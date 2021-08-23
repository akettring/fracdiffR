# fracdiffR

Fractional differnecing of xts timeseries with fixed width window.
The algorithm is described by Lopez de Prado, and also Ke Gui here (for python):
https://medium.com/swlh/fractionally-differentiated-features-9c1947ed2b55

This implementation features a novel innovation... by default, 
the series is transformed by rolling cusum of ROC "on the fly". 
This forces stationarity of the series and makes multiple series comparable.

Another addition is the ability to explicitly define the window size.
By default the window size is defined by a lower threshold for weight.


## Installation

To get the current development version from github:

```R
# install.packages("devtools")
devtools::install_github("akettring/fracdiffR")
```


## Key Features

In the simplest case, an xts series is transformed by fractional differencing 
with the following default parameters:
```R
transform_FD(x, trans_by_roc=TRUE, d=0.5, threshold=1e-4)
```


The function `get_weights_FD()` generates a weight series useful for optimization

```R
# The weights decay as expected...
get_weights_FD() %>% head()
[1]  1.00000000 -0.50000000 -0.12500000 -0.06250000 -0.03906250 -0.02734375

# What is the minimum length of the series by deault?
> get_weights_FD(d=0.5, threshold=1e-4) %>% length()
[1] 201

# relaxing the threshold leads to shorter series...
> get_weights_FD(d=0.5, threshold=1e-3) %>% length()
[1] 45

# less differntiation leads to longer series...
> get_weights_FD(d=0.25, threshold=1e-4) %>% length()
[1] 446

# fixed window size ignores other thresholding rules...
> get_weights_FD(d=0.5, window=100) %>% length()
[1] 100

```


The function `demo_FD()` implements the following example workflow:
```R
x <- FANG %>% subset(symbol == "FB")    # get series of FB prices
x <- xts(x$close, order.by=x$date)      # make and xts object of the close prices
x <- cbind.xts(x, transform_FD(x))      # tranform and bind with original series
```


This `demo_FD() %>% tail()` returns a transformed series that looks like this:
```
                x transform_FD.x.
2016-12-22 117.40      -1.7374399
2016-12-23 117.27      -1.1111172
2016-12-27 118.01      -0.2562332
2016-12-28 116.92      -1.3466745
2016-12-29 116.35      -1.3540706
2016-12-30 115.05      -2.0624452
```