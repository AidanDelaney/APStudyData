doPlot <- function(x, col, col.fn = function(col) hcl(col * 360, 130, 60), alpha=0.3, main=NULL, edges=200, border=NA, col.txt=1, spec=c(), ...) {
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
  for (i in seq.int(n))
    polygon(x$centers[i, 1] +  x$diameters[i] * sx, x$centers[i, 2] + x$diameters[i] * sy, col = col[i], border = border[i])
  # if col.txt is not NA, plot the circle text
  
  if (!all(is.na(col.txt))) {
    for(i in seq.int(n)) {
      r <- (x$diameters[i]) / 2
      text(x$centers[i, 1] - r, x$centers[i ,2] + r, x$labels[i], col= border[i])
      print(x$centers[i])
    }
  }
  
  for(zone in names(spec)) {
    p <- getZoneCentroid(x, zone)
    if(is.double(p$value$x)) {
      print(paste0(p$value$x, ",", p$value$y))
      text(p$value$x, p$value$y, spec[zone])
    }
  }
  
  ##if (!all(is.na(col.txt))) text(x$centers, x$labels, col=col.txt)
  # finish with title
  title(main = main, ...)
  invisible(NULL)
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

getZoneCentroid <- function (vd, zone, url, ...) {
  if(missing(vd)) {
    stop("VennDiagram must be specified")
  }
  
  circles <- vdToCircles(vd)
  json <- jsonlite::toJSON(list("circles" = circles))
  print(json)
  
  if(missing(url)) {
    # if you don't provide a URL we'll use a test one.
    resp <- doFormPost(paste0('http://localhost:8080/centroids/', zone), json)
  } else {
    resp <- doFormPost(url, json)
  }
  structure(fromJSON(resp), class="Point2D")
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