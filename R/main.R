
# fractional differnecing of xts timeseries with fixed width window
# ... as described by Prado, and here (for python) ...
# https://medium.com/swlh/fractionally-differentiated-features-9c1947ed2b55
# ... by default, series is transformed by ROC "on the fly"

library("tidyverse")
library("reshape2")
library("tidyquant")


# get a series of weights for fractional difference within a fixed window
# 1. by default window size is defined by a cutoff for the smallest weight
# 2. alternatively the window size may be explicitly defined
get_weights_FD <- function(d=0.5, threshold=1e-4, window){

    # 0. intialize values for weight series
    w <- c(1.0)
    w_i <- 1.0
    k <- 1

     # 1. define window size by threshold cutoff ...
    if (missing(window)) {
        while(  abs(w_i) > threshold ){
            w_i <- -tail(w,1)/k*(d-k+1)
            w <- c(w,w_i)
            k <- k+1
        }

    # 2. otherwise if window is explicitly defined ...
    } else {
        while( k < window ){
            w_i <- -tail(w,1)/k*(d-k+1)
            w <- c(w,w_i)
            k <- k+1
        }
    }

    return(w)
}


# fractionally differentiate an xts timseries
transform_FD <- function(x, trans_by_roc=TRUE, d=0.5, threshold=1e-4, window){

    # get the weights for transformation
    w <- get_weights_FD(d, threshold=threshold, window=window)

    # widow size can't be larger than the size of data
    if (length(w) > length(x)){
        print("Series is too short to differnetiate with given parameters!")
        break
    }

    # transform the timeseries using the weights
    df <- xts(order.by = index(x))
    for (i in seq(length(w),length(x))){
        # get the timeseries indexes
        i_0_index <- index(x)[i-length(w)+1]    # first time point
        i_1_index <- index(x)[i]                # last time point
        # get the timeseries data
        data <- x[between(index(x),i_0_index,i_1_index)] %>% rev()

        # by default, transform by rolling cusum of %ROC
        if (trans_by_roc==TRUE){
            data <- ROC(data, type="discrete") * 100
            data <- data %>% as.vector() %>% replace_na(0) %>% cumsum()
        }
        # dot product is fractional difference
        dotprod <- w %*% data
        df[i_1_index] <- dotprod
    }

    return(df)
}


# Demo the FD function using default settings
# on FB closing prices from the FANG dataset
demo_FD <- function(){
    x <- FANG %>% subset(symbol == "FB")
    x <- xts(x$close, order.by=x$date)
    x <- cbind.xts(x, transform_FD(x))
    return(x)
}