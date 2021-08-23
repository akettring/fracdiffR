
# fractional differnecing with fixed width window
# ... as described by Prado, and here (for python) ...
# https://medium.com/swlh/fractionally-differentiated-features-9c1947ed2b55


library("tidyverse")
library("reshape2")
library("tidyquant")


# get weights
get_weights_FD <- function(d=0.25, window=400){
    w <- c(1.0)
    w_ <- 1.0
    k <- 1
    while( k < window ){
        w_ <- -tail(w,1)/k*(d-k+1)
        w <- c(w,w_)
        k <- k+1
    }
    return(w)
}

# apply FD to a series (x)
transform_FD <- function(x, d=0.25, window=400){

    # widow size can't be larger than the size of data
    if (window > length(x)){
        print("too short")
        break
    }

    # Apply weights to values
    w <- get_weights_FD(d, window)

    df <- xts(order.by = index(x))
    for (i in seq(length(w),length(x))){
        # get the indexes
        i_0_index <- index(x)[i-length(w)+1]    # first time point
        i_1_index <- index(x)[i]                # last time point
        # get the data
        data <- x[between(index(x),i_0_index,i_1_index)] %>% rev()
        # transform by rolling cusum of %ROC
        data <- ROC(data, type="discrete") * 100
        data <- data %>% as.vector() %>% replace_na(0) %>% cumsum()
        # dot product is fractional difference
        dotprod <- w %*% data
        df[i_1_index] <- dotprod
    }

    return(df)
}