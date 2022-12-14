#' @keywords internal
KMeansSparseCluster.ver<-
  function(x, K=NULL, wbounds=NULL, nstart=20, silent=FALSE, maxiter=6, centers=NULL){
    # The criterion is : minimize_{w, C} sum_j w_j (WCSS_j - TSS_j) s.t. ||w||_2=1, ||w||_1<=s, w_j>=0
    # x is the data, nxp
    # K is the number of clusters desired
    # wbounds is a vector of L1 constraints on w, of the form  sum(abs(w))<=wbounds[i]
    if(is.null(K) && is.null(centers)) stop("Must provide either K or centers.")
    if(!is.null(K) && !is.null(centers)){
      if(nrow(centers)!=K) stop("If K and centers both are provided, then nrow(centers) must equal K!!!")
      if(nrow(centers)==K) K <- NULL
    }
    if(!is.null(centers) && ncol(centers)!=ncol(x)) stop("If centers is provided, then ncol(centers) must equal ncol(x).")
    if(is.null(wbounds)) wbounds <- seq(1.1, sqrt(ncol(x)), len=20)
    if(min(wbounds)<=1) stop("wbounds should be greater than 1")
    wbounds <- c(wbounds) # In case wbounds is a single number, turn it into a vector
    out <- list()
    if(!is.null(K)) Cs <- stats::kmeans(x, centers=K, nstart=nstart)$cluster
    if(is.null(K)) Cs <- stats::kmeans(x, centers=centers)$cluster
    for(i in 1:length(wbounds)){
      if(length(wbounds)>1 && !silent) cat(i,fill=FALSE)
      ws <- rep(1/sqrt(ncol(x)), ncol(x)) # Start with equal weights on each feature
      ws.old <- stats::rnorm(ncol(x))
      store.bcss.ws <- NULL
      niter <- 0
      while((sum(abs(ws-ws.old))/sum(abs(ws.old)))>1e-4 && niter<maxiter){
        if(!silent) cat(niter, fill=FALSE)
        niter <- niter+1
        ws.old <- ws
        if(!is.null(K)){
          if(niter>1) Cs <- utils::getFromNamespace("UpdateCs","sparcl")(x, K, ws, Cs) # if niter=1, no need to update!!
        } else {
          if(niter>1) Cs <- utils::getFromNamespace("UpdateCs","sparcl")(x, nrow(centers), ws, Cs) # if niter=1, no need to update!!
        }
        ws <- UpdateWs.ver(x, Cs, wbounds[i])
        store.bcss.ws <- c(store.bcss.ws, sum(utils::getFromNamespace("GetWCSS","sparcl")(x, Cs)$bcss.perfeature*ws))
      }
      out[[i]] <- list(ws=ws, Cs=Cs, wcss=utils::getFromNamespace("GetWCSS","sparcl")(x, Cs, ws), crit=store.bcss.ws, wbound=wbounds[i])
    }
    if(!silent) cat(fill=TRUE)
    #  if(length(wbounds)==1){
    #    out <- out[[1]]
    #    class(out) <- "kmeanssparse"
    #    return(out)
    #  }
    #  class(out) <- "multikmeanssparse"
    #  return(out)
    class(out) <- "KMeansSparseCluster"
    return(out)
  }
