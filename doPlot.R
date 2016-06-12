library(shape)
library(foreach)
library(RCurl)

doPlot <- function(x, col, col.fn = function(col) hcl(col * 360, 130, 60), alpha=0.3, main=NULL, edges=200, border=NA, col.txt=1, spec=c(), areaLabels=TRUE, ...) {
  # calculate total extents
  xtp <- x$centers + x$diameters / 2
  xtm <- x$centers - x$diameters / 2
  xr <- range(c(xtp[,1], xtm[,1]))
  yr <- range(c(xtp[,2], xtm[,2]))
  # create canvas
  plot.new()
  plot.window(xr, yr, "", asp = 1)
  # adjust alpha for all colors if specified
  n <- length(x$diameters)
  if (missing(col)) col <- col.fn(x$colors)
  if (length(col) < n) col <- rep(col, length.out=n)
  if (!is.na(alpha)) {
    col <- col2rgb(col) / 255
    col <- rgb(col[1,], col[2,], col[3,], alpha)
  }
  # prepare circle coordinates
  s <- seq.int(edges) / edges * 2 * pi
  sx <- cos(s) / 2 # VD uses diameter, not radius
  sy <- sin(s) / 2
  if (!is.null(border)) border <- rep(border, length.out=n)
  
  # plot all circles
  for (i in seq.int(n)) {
    lab <- x$labels[i]
    colour <- getColour(border, x$labels, lab)
    polygon(x$centers[i, 1] +  x$diameters[i] * sx, x$centers[i, 2] + x$diameters[i] * sy, col = col[i], border = colour, lwd=3)
  # if col.txt is not NA, plot the circle text
  }
  
  if (!all(is.na(col.txt))) {
    for(i in seq.int(n)) {
      r <- (x$diameters[i]) / 2
      lab <- x$labels[i]
      colour <- getColour(border, x$labels, lab)
      text(x$centers[i, 1] - r, x$centers[i ,2] + r, x$labels[i], col= colour)
    }
  }
  
  if(areaLabels) {
    for(zone in names(spec)) {
      p <- getZoneCentroid(x, zone)
      if(is.double(p$value$x)) {
        text(p$value$x, p$value$y, spec[zone])
      }
    }
  }
  
  ##if (!all(is.na(col.txt))) text(x$centers, x$labels, col=col.txt)
  # finish with title
  title(main = main, ...)
  invisible(NULL)
}

plotCircles <- function(d, spec, border=NA) {
  
  if(0 == length(d$circles)) {
    return()
  }
  max_radius <- max(d$circles$radius)
  max_x <- max(d$circles$x)
  min_x <- min(d$circles$x)
  max_y <- max(d$circles$y)
  min_y <- min(d$circles$y)
  
  # Create a large enough canvas
  emptyplot(xlim=c(min_x - max_radius, max_x + max_radius), ylim=c(min_y - max_radius, max_y + max_radius))
  
  for(i in seq(nrow(d$circles))) {
    radius <- d$circles[i,][['radius']]
    cx <- d$circles[i,][['x']]
    cy <- d$circles[i,][['y']]
  # sapply(d$circles, function (x) {}
    lab <- d$circles[i,]['label']
    colour <- getColour(border, d$circles[["label"]], lab)
    filledcircle(r1=radius, mid=c(cx, cy), col=rgb(1,1,1,0), lcol=colour, lwd=3)
    text(cx - radius, cy + radius, lab, col=colour)
  }
  
    for(zone in names(spec)) {
      p <- getZC(d, zone)
      if(is.double(p$value$x)) {
        text(p$value$x, p$value$y, spec[zone])
      }
    }
  # })
  
}

# An attempt to get the same colour given a label and list of labels
getColour <- function (colours, labels, label) {
  colours[[ match(label, unique(sort(labels))) ]]
}

vdToCircles <- function (vd) {
  n <- length(vd$diameters)
  circles <- data.frame()
  
  # Need to iteratively build a list of circles
  #   - there's no structure in vd to map over :()
  for(i in seq.int(n)) {
    c <- data.frame(label= vd$labels[i], x=vd$centers[i, 1], y=vd$centers[i, 2], radius = vd$diameters[[i]]/2.0)
    circles <- rbind(circles, c)
  }
  
  circles
}

getZC <- function(circles, zone, url, ...) {
  json <- jsonlite::toJSON(circles)
  
  if(missing(url)) {
    # if you don't provide a URL we'll use a test one.
    resp <- doFormPost(paste0('http://localhost:8080/centroids/', zone), json)
  } else {
    resp <- doFormPost(url, json)
  }
  structure(fromJSON(resp), class="Point2D")
}
getZoneCentroid <- function (vd, zone, url, ...) {
  if(missing(vd)) {
    stop("VennDiagram must be specified")
  }
  
  circles <- vdToCircles(vd)
  getZC(list("circles" = circles), zone, url)
}

getICirclesDiagram <- function(combinations) {
  j <- foreach(i = 1:length(combinations)) %do% combinations[i]
  l <- list("area_specifications" = j)
  json <- rjson::toJSON(l)
  
  jsonlite::fromJSON(doFormPost("http://localhost:8080/icircles/layout", json))
}

doFormPost <- function (url, json) {
  #if(!(url.exists(url, .opts=list(post=1L)))) {
  #  stop(paste("The requested URL cannot be contacted: ", url))
  #}
  httpheader <- c(Accept="application/json; charset=UTF-8",
                  "Content-Type"="application/json")
  response <- postForm(url, .opts=list(httpheader=httpheader
                                       ,postfields=json))
}