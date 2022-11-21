
<!-- README.md is generated from README.Rmd. Please edit that file -->

# weightedCC

<!-- badges: start -->

[![R-CMD-check](https://github.com/candsj/weightedCC/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/candsj/weightedCC/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of weightedCC is to …

## Installation

You can install the development version of weightedCC from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("candsj/weightedCC")
```

## Example

# How wcc works

First, we generate four different type datasets with the same clustering
structure (3 clusters of equal size) and different levels of noise.

``` r
n1=20
n2=20
n3=20
n = n1+n2+n3
p=30
p1 =5
p2 = 5
p3 = 5

true.class=c(rep(1,n1),rep(2,n2),rep(3,n3))
  ################# normal distribution ####################
  c1=matrix(rnorm(n1*p1,mean=2.2,sd=1.7), ncol=p1,nrow=n1)
  c2=matrix(rnorm(n2*p2,mean=1.6, sd=1.7), ncol=p2,nrow=n2)
  c3=matrix(rnorm(n3*p3,mean=1, sd=1.7), ncol=p3,nrow=n3)
  
  normData = matrix(rnorm(n*p, mean=0, sd=1.7),nrow=n, ncol=p)
  normData[1:n1,1:p1]= c1
  normData[(n1+1):(n1+n2),(p1+1):(p1+p2)]= c2
  normData[(n1+n2+1):n,(p1+p2+1):(p1+p2+p3)]= c3
  
  noiseData = matrix(rnorm(n*p, mean=0, sd=1),nrow=n, ncol=p)
  ######## binomial data #########################
  c1=matrix(rbinom(n1*p1,size=1, prob=0.54), ncol=p1,nrow=n1)
  c2=matrix(rbinom(n2*p2,size=1, prob=0.42), ncol=p2,nrow=n2)
  c3=matrix(rbinom(n3*p3,size=1, prob=0.3), ncol=p3,nrow=n3)
  
  binomData = matrix(rbinom(n*p, size=1, prob=0.1),nrow=n, ncol=p)
  binomData[1:n1,1:p1]= c1
  binomData[(n1+1):(n1+n2),(p1+1):(p1+p2)]= c2
  binomData[(n1+n2+1):n,(p1+p2+1):(p1+p2+p3)]= c3
  
  ######### poisson data ############################
  c1=matrix(rpois(n1*p1,lambda=1.9), ncol=p1,nrow=n1)
  c2=matrix(rpois(n2*p2,lambda=1.5), ncol=p2,nrow=n2)
  c3=matrix(rpois(n3*p3,lambda=1), ncol=p3,nrow=n3)
  
  poisData = matrix(rpois(n*p, lambda=0.6),nrow=n, ncol=p)
  poisData[1:n1,1:p1]= c1
  poisData[(n1+1):(n1+n2),(p1+1):(p1+p2)]= c2
  poisData[(n1+n2+1):n,(p1+p2+1):(p1+p2+p3)]= c3

  ################## multinomial distribution ##############
  c1=matrix(sample(1:3,size=n1*p1, replace=TRUE, prob=c(0.8,0.15,0.05)), ncol=p1,nrow=n1)
  c2=matrix(sample(1:3,size=n2*p2, replace=TRUE, prob=c(0.3,0.4,0.3)), ncol=p2,nrow=n2)
  c3=matrix(sample(1:3,size=n3*p3, replace=TRUE, prob=c(0.05,0.15,0.8)), ncol=p3,nrow=n3)
  
  multData = matrix(sample(1:3,size=n*p, replace=TRUE, prob=c(0.33,0.33,0.33)),nrow=n, ncol=p)
  multData[1:n1,1:p1]= c1
  multData[(n1+1):(n1+n2),(p1+1):(p1+p2)]= c2
  multData[(n1+n2+1):n,(p1+p2+1):(p1+p2+p3)]= c3
  
  
  #biID = seq(1,p,2)
  #multData[,biID] = binomData[,biID]
  
  ### some variables only have one category; need to remove these variables
  ncat = function(x){length(unique(x))}
  len = apply(binomData,2,ncat)
  unicat = which(len==1)
  if (length(unicat)>0) {
    binomData = binomData[,-unicat]
  }
  
```

Now we can use the `consensusclustering` function to compute a consensus
matrix for each dataset.

``` r
  normRes=consensuscluster(normData,K=3,B=1000,pItem = 0.8,pFeature = 0.8 ,clMethod ="kmeans",finalclmethod="pam")
  binomRes=consensuscluster(binomData,K=3,B=1000,pItem = 0.8,pFeature = 0.8 ,clMethod ="kmeans",finalclmethod="pam")
  poisRes=consensuscluster(lopoisData,K=3,B=1000,pItem = 0.8,pFeature = 0.8 ,clMethod ="kmeans",finalclmethod="pam")
  multRes=consensuscluster(multData,K=3,B=1000,pItem = 0.8,pFeature = 0.8 ,clMethod ="kmeans",finalclmethod="pam")

  normRes1=consensuscluster(normData,K=3,B=1000,pItem = 0.8,pFeature = 0.8 ,clMethod ="hclust",finalclmethod="pam")
  binomRes1=consensuscluster(binomData,K=3,B=1000,pItem = 0.8,pFeature = 0.8 ,clMethod ="hclust",dist = "binary",finalclmethod="pam")
  poisRes1=consensuscluster(poisData,K=3,B=1000,pItem = 0.8,pFeature = 0.8 ,clMethod ="hclust",dist = "jaccard",finalclmethod="pam")
  multRes1=consensuscluster(multData,K=3,B=1000,pItem = 0.8,pFeature = 0.8 ,clMethod ="hclust",dist = "hamming",finalclmethod="pam")
```

Then we could perform one layer weighted consensus clustering.

``` r
  res.all <- c(list(normRes),list(binomRes),list(poisRes),list(multRes))
  weights <-weightcal(res.all)
  wcm=weights[1]*res.all[[1]]$consensusMatrix+weights[2]*res.all[[2]]$consensusMatrix+
    weights[3]*res.all[[3]]$consensusMatrix+weights[4]*res.all[[4]]$consensusMatrix
  distances <- stats::as.dist(1 - wcm)
  weight_clusterLabels <- pam(distances,3,diss = TRUE,metric = "euclidean" )$clustering
  ari.weight<- adjustedRandIndex(true.class, weight_clusterLabels)
```

Or we could perform two-layer weighted consensus clustering.

``` r
  #norm
  res.norm <- c(list(normRes),list(normRes1))
  weight.norm<- weightcal(res.norm)
  wcm=weight.norm[1]*res.norm[[1]]$consensusMatrix+weight.norm[2]*res.norm[[2]]$consensusMatrix
  distances <- stats::as.dist(1 - wcm)
  weight_clusterLabels <-pam(distances,3,diss = TRUE,metric = "euclidean" )$clustering
  weightnormRes=list(consensusMatrix=wcm,class=weight_clusterLabels)
  
  #binom
  res.binom <- c(list(binomRes),list(binomRes1))
  weight.binom <- weightcal(res.binom)
  wcm=weight.binom[1]*res.binom[[1]]$consensusMatrix+weight.binom[2]*res.binom[[2]]$consensusMatrix
  distances <- stats::as.dist(1 - wcm)
  weight_clusterLabels <- pam(distances,3,diss = TRUE,metric = "euclidean" )$clustering
  weightbinomRes=list(consensusMatrix=wcm,class=weight_clusterLabels)
  
  #poisson
  res.pois <- c(list(poisRes),list(poisRes1))
  weight.pois <- weightcal(res.pois)
  wcm=weight.pois[1]*res.pois[[1]]$consensusMatrix+weight.pois[2]*res.pois[[2]]$consensusMatrix
  distances <- stats::as.dist(1 - wcm)
  weight_clusterLabels <-pam(distances,3,diss = TRUE,metric = "euclidean" )$clustering
  weightpoisRes=list(consensusMatrix=wcm,class=weight_clusterLabels)
  
  #mult
  res.mult <- c(list(multRes),list(multRes1))
  weight.mult <- weightcal(res.mult)
  wcm=weight.mult[1]*res.mult[[1]]$consensusMatrix+weight.mult[2]*res.mult[[2]]$consensusMatrix
  distances <- stats::as.dist(1 - wcm)
  weight_clusterLabels <- pam(distances,3,diss = TRUE,metric = "euclidean" )$clustering
  weightmultRes=list(consensusMatrix=wcm,class=weight_clusterLabels)
  
  #2 layer wcm
  res.wcm <- c(list(weightnormRes),list(weightbinomRes),list(weightpoisRes),list(weightmultRes))
  weight.wcm <- weightcal(res.wcm)
  wcm=weight.wcm[1]*res.wcm[[1]]$consensusMatrix+weight.wcm[2]*res.wcm[[2]]$consensusMatrix+
    weight.wcm[3]*res.wcm[[3]]$consensusMatrix+weight.wcm[4]*res.wcm[[4]]$consensusMatrix
  distances <- stats::as.dist(1 - wcm)
  weight_clusterLabels <- pam(distances,3,diss = TRUE,metric = "euclidean" )$clustering
  end.time3=Sys.time()
  ari.wcm <- adjustedRandIndex(true.class, weight_clusterLabels)
```

The same can be done simply using the function
`WeightedConsensusCluster`

``` r
#one layer
  data_for_wcc <- list()
  data_for_wcc[[1]]=normData
  data_for_wcc[[2]]=binomData
  data_for_wcc[[3]]=poisData
  data_for_wcc[[4]]=multData
  wcc <- WeightedConsensusCluster(data_for_wcc, method="one layer", individualK = rep(3, 4),
                                   globalK = 3, pFeature = 0.8 ,ccClMethods = "kmeans",
                                    ccDistHCs = "euclidean",hclustMethod = "average",finalclmethod="hclust",
                                    finalhclustMethod = "average",Silhouette=TRUE)

#two-layer
  data_for_wcc <- list()
  data_for_wcc[[1]]=normData
  data_for_wcc[[2]]=binomData
  data_for_wcc[[3]]=lopoisData
  data_for_wcc[[4]]=multData
  data_for_wcc[[5]]=normData
  data_for_wcc[[6]]=binomData
  data_for_wcc[[7]]=poisData
  data_for_wcc[[8]]=multData
  wcc <- WeightedConsensusCluster(data_for_wcc, method="two-layer", individualK = rep(3, 8),
                     globalK = 3, pFeature = 0.8 ,ccClMethods = c("kmeans","kmeans","kmeans","kmeans",
                                                                  "hclust","hclust","hclust","hclust"),
                     ccDistHCs = c("euclidean","euclidean","euclidean","euclidean",
                                   "euclidean","binary","jaccard","hamming"),hclustMethod = "average",finalclmethod="hclust",
                                    finalhclustMethod = "average",Silhouette=TRUE)
```
