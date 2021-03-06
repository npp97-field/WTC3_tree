#chamber label function--------------------------------------------------------------------------------
chlab_func <- function(x){
  x$chamber <- ifelse(x$chamber <= 9, paste("0", x$chamber, sep=""), x$chamber)
  x$chamber <- as.factor(paste("ch", x$chamber, sep=""))
  return(x)
}

# standard error function--------------------------------------------------------------------------------
se <- function(x) sd(x)/sqrt(length(x))

#bar plot function--------------------------------------------------------------------------------

bar <- function(dv, factors, dataframe, percentage=FALSE, errbar=!percentage, half.errbar=TRUE, conf.level=.95, 
                xlab=NULL, ylab=NULL, main=NULL, names.arg=NULL, bar.col="black", whisker=.015,args.errbar=NULL,
                legend=TRUE, legend.text=NULL, args.legend=NULL,legend.border=FALSE, box=TRUE, args.yaxis=NULL, 
                mar=c(5,4,3,2),...){
  axes=!percentage
  dv.name<-substitute(dv)
  if(length(dv.name)>1) stop("'dv' only takes one variable")
  dv.name<-as.character(dv.name)
  dv<-dataframe[[dv.name]]
  fnames<-substitute(factors)
  if(length(fnames)==1){
    factors<-as.character(fnames)
    nf<-1
  }else{
    factors<-as.character(fnames[-1L])
    nf<-length(factors)
  }
  if(nf>2) stop("This function accepts no more than 2 factors \n",
                "\t-i.e., it only plots one-way or two-way designs.")
  if(percentage & errbar){
    warning("percentage=TRUE; error bars were not plotted")
    errbar<-FALSE
  }
  if(!percentage) xbars<-tapply(dv, dataframe[,factors], mean, na.rm=TRUE)
  else {
    xbars<-tapply(dv, list(interaction(dataframe[,factors], lex.order=TRUE)), mean, na.rm=TRUE)
    if(sum(na.omit(dv)!=0&na.omit(dv)!=1)>0) 
      stop("Data points in 'dv' need to be 0 or 1 in order to set 'percentage' to TRUE")
    xbars<-rbind(xbars, 1-xbars)*100
  }
  if(errbar){
    se<-tapply(dv, dataframe[,factors], sd, na.rm=TRUE)/sqrt(tapply(dv, dataframe[,factors], length))
    conf.level=1-(1-conf.level)/2
    lo.bar<-xbars-se*qnorm(conf.level)
    hi.bar<-xbars+se*qnorm(conf.level)	
  }
  extras<-list(...)
  if(legend & !percentage){
    if(is.null(legend.text))
      legend.text<-sort(unique(dataframe[[factors[1]]]))
    args.legend.temp<-list(x="topright", bty=if(!legend.border)"n" else "o",
                           inset=c(0,0))
    if(is.list(args.legend))
      args.legend<-modifyList(args.legend.temp, args.legend)
    else 
      args.legend<-args.legend.temp
  } else if(legend & percentage){
    if(is.null(legend.text)) 
      legend.text<-c("1", "0")
    args.legend.temp<-list(x="topright", bty=if(!legend.border)"n" else "o",
                           inset=c(0,0))
    if(is.list(args.legend))
      args.legend<-modifyList(args.legend.temp, args.legend)
    else 
      args.legend<-args.legend.temp
  } else if(!legend){
    args.legend<-NULL
    legend.text<-NULL
  }
  if(errbar && legend && !percentage) ymax<-max(hi.bar)+max(hi.bar)/20
  else if(errbar && legend && percentage) ymax<-115
  else if(errbar && !legend) ymax <- max(xbars)
  else if(!errbar && legend && percentage) ymax<-110	
  else if(!errbar) ymax<-max(xbars) + max(xbars)/20
  if(!percentage){
    args.barplot<-list(beside=TRUE, height=xbars, ylim=c(0, ymax), main=main, names.arg=names.arg,
                       col=hcl(h=seq(0,270, 270/(length(unique(dataframe[[factors[1]]]))))[-length(unique(dataframe[[factors[1]]]))]),
                       legend.text=legend.text, args.legend=args.legend, xpd=TRUE,
                       xlab=if(is.null(xlab)) factors[length(factors)] else xlab,
                       ylab=if(is.null(ylab)) dv.name else ylab, axes=axes)
  }else{
    args.barplot<-list(beside=TRUE, height=xbars, ylim=c(0, ymax),  main=main, names.arg=names.arg,
                       col=hcl(h=seq(0,270, 270/(length(unique(dataframe[[factors[1]]]))))[-length(unique(dataframe[[factors[1]]]))]),
                       legend.text=legend.text, args.legend=args.legend, xpd=TRUE,
                       xlab=if(is.null(xlab)) " "[length(factors)] else xlab,
                       ylab=if(is.null(ylab)) "percentage" else ylab, axes=axes)		
  }
  args.barplot<-modifyList(args.barplot, extras)
  errbars = function(xvals, cilo, cihi, whisker, nc, args.errbar = NULL, half.errbar=TRUE) {
    if(half.errbar){
      cilo<-(cihi+cilo)/2
    }
    fixedArgs.bar = list(matlines, x=list(xvals), 
                         y=lapply(split(as.data.frame(t(do.call("rbind", 
                                                                list(cihi, cilo)))),1:nc),matrix, 
                                  nrow=2, byrow=T))
    allArgs.bar = c(fixedArgs.bar, args.errbar)
    whisker.len = whisker*(par("usr")[2] - par("usr")[1])/2
    whiskers = rbind((xvals - whisker.len)[1,],
                     (xvals + whisker.len)[1,])
    fixedArgs.lo = list(matlines, x=list(whiskers), 	
                        y=lapply(split(as.data.frame(t(do.call("rbind", 
                                                               list(cilo, cilo)))), 1:nc), matrix, nrow=2, byrow=T))
    allArgs.bar.lo = c(fixedArgs.lo, args.errbar)
    fixedArgs.hi = list(matlines, x=list(whiskers), 
                        y=lapply(split(as.data.frame(t(do.call("rbind", 
                                                               list(cihi, cihi)))), 1:nc), matrix, nrow=2, byrow=T))
    allArgs.bar.hi = c(fixedArgs.hi, args.errbar)  
    invisible(do.call(mapply, allArgs.bar))
    if(!half.errbar) invisible(do.call(mapply, allArgs.bar.lo))
    invisible(do.call(mapply, allArgs.bar.hi))
  }
  par(mar=mar)
  errloc<-as.vector(do.call(barplot, args.barplot))
  if(errbar){
    errloc<-rbind(errloc, errloc)
    lo.bar<-matrix(as.vector(lo.bar))
    hi.bar<-matrix(as.vector(hi.bar))
    args.errbar.temp<-list(col=bar.col, lty=1)
    args.errbar<-if(is.null(args.errbar)|!is.list(args.errbar)) 
      args.errbar.temp
    else if(is.list(args.errbar)) 
      modifyList(args.errbar.temp, args.errbar)
    errbars(errloc, cilo=lo.bar, cihi=hi.bar, nc=1, whisker=whisker, 
            args.errbar=args.errbar, half.errbar=half.errbar)
  }
  if(box) box()
  if(percentage){
    args.yaxis.temp<-list(at=seq(0,100, 20), las=1)
    args.yaxis<-if(!is.list(args.yaxis)) args.yaxis.temp else modifyList(args.yaxis.temp, args.yaxis)
    do.call(axis, c(side=2, args.yaxis))
  }
}



#leafformat func------------------------------------------------
leafformat <- function(x) {
  x$Date <- as.Date(x$Date, format = "%d/%m/%Y")
  x$Month <- month(x$Date, label=TRUE)
  x$year <- year(x$Date)
  x$wp <- with(x, ((water_potential/10)*-1))
  x <- merge(x, treatments, all=TRUE)
  x$chamber <- as.character(x$chamber)
  x$drydown <- ifelse(x$month %in% c("Mar", "Apr") & x$chamber %in%c("ch01", "ch03", "ch04", "ch06", "ch08", "ch11"), 
                      "drought", "control")
  x$lma <- with(x, leaf_mass/leaf_area)
  x_ss <- subset(x, select= -c(Date, water_potential))
  monthorder<-order(x_ss$Month, by=x_ss$chamber)
  x_ss <- x_ss[monthorder,]
  row.names(x_ss)<-NULL
  
  return(x_ss)
}


#gmdata format func--------------------------------------------------
gmformat <- function(df) {
  df <- merge(df, treatments, all=TRUE)
  df$chamber <- as.character(df$chamber)
  df$ID <- paste(df$leaf, df$type, sep="-")
  df$ID <- as.factor(df$ID)
  df$drydown <- ifelse(df$month %in% c("march", "apr") & df$chamber %in%c("ch01", "ch03", "ch04", "ch06", "ch08", "ch11"), 
                       "drought", "control")
  return(df)
}

#par data format func---------------------------------------------------------------
parformat <- function(df) {
  df <- merge(df, treatments, all=TRUE)
  df$chamber <- as.character(df$chamber)
  df$ID <- paste(df$leaf_type, df$par_type, sep="-")
  df$ID <- as.factor(df$ID)
  df$drydown <- ifelse(df$month %in% c("Mar", "Apr") & df$chamber %in%c("ch01", "ch03", "ch04", "ch06", "ch08", "ch11"), 
                       "drought", "control")
  df$drydown <- as.factor(df$drydown)
  return(df)
}

#extract summary data---------------------------------------------------------------
getp <- function(x)x$p.value
getdiffmean <- function(m)m$estimate


#adds campaign Date and orders by ID and Date-------------------------------------------------------------
add_Month<- function(x){
  
  x$Month <-ifelse(x$campaign == 1, "Oct", x$campaign)
  x$Month <-ifelse(x$campaign == 2, "Dec", x$Month )
  x$Month <-ifelse(x$campaign == 3, "Jan", x$Month )
  x$Month <-ifelse(x$campaign == 4, "Feb", x$Month )
  x$Month <-ifelse(x$campaign == 5, "Mar", x$Month )
  x$Month <-ifelse(x$campaign == 6, "Apr", x$Month )
  x$Month <- as.factor(x$Month)
  return(x)
}

add_campaign<- function(x){
  
  x$campaign <-ifelse(x$Month == "Oct", 1, x$Month)
  x$campaign <-ifelse(x$Month == "Dec", 2, x$campaign )
  x$campaign <-ifelse(x$Month == "Jan", 3, x$campaign )
  x$campaign <-ifelse(x$Month == "Feb", 4, x$campaign )
  x$campaign <-ifelse(x$Month == "Mar", 5, x$campaign )
  x$campaign <-ifelse(x$Month == "Apr", 6, x$campaign )
  return(x)
}


#add treatments------------------------------------------------------------------------------------------------------
addtrt_func <- function(x){
  x <- merge(x, treatments)
  x$temp <- as.factor(x$temp)
  x$drydown <- as.factor(ifelse(x$Month %in% c("Mar", "Apr") & x$chamber %in%c("ch01", "ch03", "ch04", "ch06", "ch08", "ch11"), 
                      "drought", "control"))
  return(x)
}

###function to create a unique sample id from user specific variable column names-----------------------------------

chooseidfunc <- function(dfr, varnames, sep="-"){
  dfr$id <- as.factor(apply(dfr[,varnames], 1, function(x)paste(x, collapse=sep)))
  return(dfr)
}



###3 functions (fitgam, addpoly, and smooth plot) use for ACi


#' Function for smoothplot. Probably not use otherwise.
fitgam <- function(X,Y,dfr, k=-1, R=NULL){
  dfr$Y <- dfr[,Y]
  dfr$X <- dfr[,X]
  if(!is.null(R)){
    dfr$R <- dfr[,R]
    model <- 2
  } else model <- 1
  dfr <- droplevels(dfr)
  
  
  if(model ==1){
    g <- gam(Y ~ s(X, k=k), data=dfr)
  }
  if(model ==2){
    g <- gamm(Y ~ s(X, k=k), random = list(R=~1), data=dfr)
  }
  
  return(g)
}

addpoly <- function(x,y1,y2,col=alpha("lightgrey",0.8),...){
  ii <- order(x)
  y1 <- y1[ii]
  y2 <- y2[ii]
  x <- x[ii]
  polygon(c(x,rev(x)), c(y1, rev(y2)), col=col, border=NA,...)
}


#' Plot a generalized additive model
#' @param x Variable for X axis (unquoted)
#' @param y Variable for Y axis (unquoted)
#' @param data Dataframe containing x and y
#' @param kgam the \code{k} parameter for smooth terms in gam.
#' @param R An optional random effect (quoted)
#' @param log Whether to add log axes for x or y (but no transformations are done).
#' @param fitoneline Whether to fit only 
smoothplot <- function(x,y,g=NULL,data,
                       fittype=c("gam","lm"),
                       kgam=4,
                       R=NULL,
                       randommethod=c("lmer","aggregate"),
                       log="",
                       axes=TRUE,
                       fitoneline=FALSE,
                       pointcols=NULL,
                       linecols=NULL, 
                       xlab=NULL, ylab=NULL,
                       polycolor=alpha("lightgrey",0.7),
                       plotit=TRUE, add=FALSE,
                       ...){
  
  fittype <- match.arg(fittype)
  randommethod <- match.arg(randommethod)
  if(log != "")require(magicaxis)
  
  if(!is.null(substitute(g))){
    data$G <- as.factor(eval(substitute(g),data))
  } else {
    fitoneline <- TRUE
    data$G <- 1
  }
  data$X <- eval(substitute(x),data)
  data$Y <- eval(substitute(y),data)
  data <- droplevels(data)
  
  data <- data[!is.na(data$X) & !is.na(data$Y) & !is.na(data$G),]
  
  if(class(data$X) == "Date"){
    xDate <- TRUE
    data$X <- as.numeric(data$X)
  } else {
    xDate <- FALSE
  }
  
  if(is.null(pointcols))pointcols <- palette()
  if(is.null(linecols))linecols <- palette()
  
  if(is.null(xlab))xlab <- substitute(x)
  if(is.null(ylab))ylab <- substitute(y)
  
  # If randommethod = aggregate, average by group and fit simple gam.
  if(!is.null(R) && randommethod == "aggregate"){
    data$R <- data[,R]
    
    data <- summaryBy(. ~ R, FUN=mean, na.rm=TRUE, keep.names=TRUE, data=data,
                      id=~G)
    R <- NULL
  }
  
  if(!fitoneline){
    
    d <- split(data, data$G)
    
    if(fittype == "gam"){
      fits <- lapply(d, function(x)try(fitgam("X","Y",x, k=kgam, R=R)))
      if(!is.null(R))fits <- lapply(fits, "[[", "gam")
    } else {
      fits <- lapply(d, function(x)lm(Y ~ X, data=x))
    }
    hran <- lapply(d, function(x)range(x$X, na.rm=TRUE))
  } else {
    if(fittype == "gam"){
      fits <- list(fitgam("X","Y",data, k=kgam, R=R))
      if(!is.null(R))fits <- lapply(fits, "[[", "gam")
    } else {
      fits <- list(lm(Y ~ X, data=data))
    }
    hran <- list(range(data$X, na.rm=TRUE))
    
  }
  
  if(plotit){
    if(xDate){
      data$X <- as.Date(data$X, origin="1970-1-1")
    }
    
    if(!add){
      with(data, plot(X, Y, axes=FALSE, pch=16, col=pointcols[G],
                      xlab=xlab, ylab=ylab, ...))
    } else {
      with(data, points(X, Y, pch=16, col=pointcols[G],
                        ...))
    }
    
    if(!add && axes){
      if(log=="xy")magaxis(side=1:2, unlog=1:2)
      if(log=="x"){
        magaxis(side=1, unlog=1)
        axis(2)
        box()
      }
      if(log=="y"){
        magaxis(side=2, unlog=2)
        axis(1)
        box()
      }
      if(log==""){
        if(xDate)
          axis.Date(1, data$X)
        else
          axis(1)
        axis(2)
        box()
      }
    }
    
    for(i in 1:length(fits)){
      
      if(fittype == "gam"){
        nd <- data.frame(X=seq(hran[[i]][1], hran[[i]][2], length=101))
        if(!inherits(fits[[i]], "try-error")){
          p <- predict(fits[[i]],nd,se.fit=TRUE)
          addpoly(nd$X, p$fit-2*p$se.fit, p$fit+2*p$se.fit, col=polycolor)
          lines(nd$X, p$fit, col=linecols[i], lwd=2)
        }
      }
      if(fittype == "lm"){
        pval <- summary(fits[[i]])$coefficients[2,4]
        LTY <- if(pval < 0.05)1 else 5
        predline(fits[[i]], col=linecols[i], lwd=2, lty=LTY)
      }
    }
  }
  return(invisible(fits))
}

