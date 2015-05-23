library(data.table)
library(parallel)
cl <- makeCluster(10)

# this looks backward but a list of urls and a url -> type lookup is needed
# if there's a better way to do that go ahead and change it!
mirrorTypes <- list("bioc", "cran")
names(mirrorTypes) <- contrib.url(c(
  "http://bioconductor.statistik.tu-dortmund.de/packages/3.0/bioc",
  "http://cran.r-project.org"
))

readFormatted <- as.data.table(read.table(skip=6, sep='"', text=head(readLines('r-packages.nix'), -1)))

nixPrefetch <- function(name, version, mirrorUrl) {
  prevV <- readFormatted$V2 == name & readFormatted$V4 == version
  if (sum(prevV) == 1) as.character(readFormatted$V6[ prevV ]) else
    system(paste0("nix-prefetch-url --type sha256 ", mirrorUrl, "/", name, "_", version, ".tar.gz"), intern=TRUE)
}

formatPackage <- function(name, version, sha256, depends, imports, linkingTo, mirrorType, knownPackages) {
    attr <- gsub(".", "_", name, fixed=TRUE)
    if (is.na(depends)) depends <- "";
    depends <- unlist(strsplit(depends, split="[ \t\n]*,[ \t\n]*", fixed=FALSE))
    depends <- c(depends, unlist(strsplit(imports, split="[ \t\n]*,[ \t\n]*", fixed=FALSE)))
    depends <- c(depends, unlist(strsplit(linkingTo, split="[ \t\n]*,[ \t\n]*", fixed=FALSE)))
    depends <- sapply(depends, gsub, pattern="([^ \t\n(]+).*", replacement="\\1")
    depends <- depends[depends %in% knownPackages]
    depends <- sapply(depends, gsub, pattern=".", replacement="_", fixed=TRUE)
    depends <- paste(depends, collapse=" ")
    paste0(attr, " = derive { name=\"", name,
           "\"; version=\"", version, "\"; type=\"", mirrorType,
           "\"; sha256=\"" , sha256, "\"; depends=[" , depends, " ]; };" )
}

clusterExport(cl, c("nixPrefetch","readFormatted"))

# note that the mirrorType "names" are urls
pkgs <- as.data.table(available.packages(names(mirrorTypes), filters=c("R_version", "OS_type", "duplicates")))
pkgs <- pkgs[order(Package)]
pkgs$sha256 <- parApply(cl, pkgs, 1, function(p) nixPrefetch(p[1], p[2], p[17]))
knownPackages <- unique(pkgs$Package)
pkgs$mirrorType <- as.character(mirrorTypes[pkgs$Repository])

nix <- apply(pkgs, 1, function(p) formatPackage(p[1], p[2], p[18], p[4], p[5], p[6], p[19], knownPackages))

cat(paste0("# This file was generated from generate-r-packages.R on ", Sys.Date(), ".\n"))
cat("# DO NOT EDIT. Execute the following command to update the file.\n")
cat("#\n")
cat("# Rscript generate-r-packages.R > r-packages.nix\n")
cat("\n")
cat("{ self, derive }: with self; {\n")
cat(paste(nix, collapse="\n"), "\n")
cat("}\n")

stopCluster(cl)
