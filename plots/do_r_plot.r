# Program description (run "Rscript do_r_plot.r -h")
#
# Author: Toni Lastusilta (VTT)  2022/01

text <- vector("character")
text[1 ] <- "  Create R plots from a GAMS GDX file"
text[2 ] <- ""
text[3 ] <- "  Expects the GDX file to contain a 3 dimensional parameter, e.g. p(x,y)"
text[4 ] <- "  First index x maps to x-axis, e.g. t1,t2,...t3 (converted to numeric)"
text[5 ] <- "  Second index y maps to categories, e.g. oil, gas, nuclear (categories)"
text[6 ] <- "  Third index contains parameter values, e.g. 9 ,7 ,5 (numeric expected)"
text[7 ] <- "  The second parameter p2(x,z) maps to a seconday y-axis (optional)"
text[8 ] <- "  Example:  Rscript do_r_plot.r plot4r.gdx -p p1 -s p2 -w 50 -a TRUE"
text[9 ] <- ""
text[10 ] <-"  version 2022-01-10"
text[11] <- ""
text[12] <- "  author Toni Lastusilta (VTT) "
program_description <- vector("character")
for (i in text) {
  program_description <- invisible(paste(program_description,i, sep="\n" ))
}

#Import libraries
library(gdxrrw)
library(ggplot2)
library(optparse)
library(tools)
library(rlang)
library(forcats)
library(reshape)
suppressMessages(library(rapportools))
suppressMessages(library(plyr))
suppressMessages(library(this.path))

# Settings 
# Use custom x-axis ticks distance for graphs (0 disabled)
custom_x_axis_tick_distance = 24
max_nr_of_custom_x_axis_ticks = 20

# Use custom y-axis ticks distance for graphs (0 disabled)
custom_y_axis_tick_distance = 10
max_nr_of_custom_y_axis_ticks = 21

#Preprocessing : set working directory
r_dir <- this.dir()
print(paste("Rscript working directory:",r_dir,sep=" "))
setwd(r_dir)

#CMD Line Option Management and Error Checking
option_list = list(
  make_option(c("-i", "--input"), type="character", default="plot4r.gdx", 
              help="Input file name (GDX) [default= %default]", metavar="character"),
  make_option(c("-o", "--output"), type="character", default="Rplots.pdf", 
              help="Output file name (PDF)  [default= %default]", metavar="character"),
  make_option(c("-p", "--parameter"), type="character", default="p1", 
              help="parameter name in gdx, expects 3-dimensional, e.g. p(x,y) [default= %default]", metavar="character"),
  make_option(c("-s", "--parameter2"), type="character", default="p2", 
              help="second parameter name in gdx, expects 3-dimensional, e.g. p2(x,y) [default= %default]", metavar="character"),
  make_option(c("-x", "--xlabel"), type="character", default="", 
              help="Optional X-axis label for plot [default= %default]", metavar="character"),
  make_option(c("-y", "--ylabel"), type="character", default="", 
              help="Optional left Y-axis label for plot [default= %default]", metavar="character"),
  make_option(c("-z", "--zlabel"), type="character", default="", 
              help="Optional right Y-axis label for plot [default= %default]", metavar="character"),
  make_option(c("-w", "--window"), type="integer", default="", 
              help="do additional plots by splitting x (x-axis) to the specified time step length [default= %default]", metavar="integer"),
  make_option(c("-a", "--archive"), type="logical", default=FALSE, 
              help="archive the created pdf in folder archive [default= %default]", metavar="logical")
    ); 
opt_parser = OptionParser(option_list=option_list, description = program_description)
opt = parse_args(opt_parser);

# Import own functions 
src_r_functions =  paste(r_dir,"/do_r_plot_functions.r",sep="")
source(src_r_functions)

#Preprocessing : delete old pdf 
pdf_name=opt$output
tryCatch({
  if(file.exists(pdf_name)){
    invisible(file.remove(pdf_name))
  }
}
, error = function(ex) { print(ex) ; stop("FAILED: see above message", call.=FALSE) }  
)

# check that gdx file and gdx reader is found
if (is.null(opt$input) || isFALSE(file.exists(opt$input))) {
  print_help(opt_parser)
  stop(sprintf("Input GDX file not found: %s/%s",getwd(),opt$input), call.=FALSE)
}
if (! require(gdxrrw))      stop ("gdxrrw package is not available")
if (0 == igdx(silent=TRUE)) stop ("the gdx shared library has not been loaded")

# read gdx parameter p of p(x,y)
df_p <- NULL
tryCatch({
  gdxName <- opt$input
  symName <- opt$parameter
  df_p  <- rgdx.param(gdxName,symName, ts=TRUE, squeeze=FALSE)
  }
, error = function(ex) { print(ex) ; stop("FAILED: see above message", call.=FALSE) }
)
# gdx error check, expecting parameter format p(x,y)
if(ncol(df_p)!=3){
  print(head(df_p))
  stop(sprintf("Symbol %s has %d columns, expected 3 (third column holds values)", symName, ncol(df_p)), call.=FALSE)
}
df_p_org <- df_p

df_p2 <- NULL
if(!is.empty(opt$parameter2)){
# read gdx parameter p2 of p2(x,y)
  tryCatch({
    gdxName <- opt$input
    symName <- opt$parameter2
    df_p2  <- rgdx.param(gdxName,symName, ts=TRUE, squeeze=FALSE)
  }
  , error = function(ex) { print(ex) ; stop("FAILED: see above message", call.=FALSE) }
  )
  # gdx error check, expecting parameter format p(x,y)
  if(ncol(df_p2)!=3){
    print(head(df_p2))
    warning(sprintf("Symbol %s ignored, it has %d columns, expected 3 (third column holds values)", symName, ncol(df_p2)), call.=FALSE)
    df_p2 <- NULL
  }
}
df_p2_org <- df_p2

# read set x and y from parameter p(x,y) if not set by swithches -x and -y
xvar_desc <- vector("character")
if(is.empty(opt$xlabel)){
  tryCatch({
    gdxName <- opt$input
    symName <- opt$parameter
    xvar=as_string(sym(colnames(df_p)[1]))
    df_x <- rgdx.set(gdxName, xvar, names=xvar, ts=TRUE)
    xvar_desc = paste(attr(df_x,"ts"), "  ")
  }
  , error = function(ex) { xvar_desc="" ; print(ex) ; print("FAILED to read set description: see above message", call.=FALSE) }
  )
}else{
  xvar_desc = opt$xlabel
}
yvar_desc <- vector("character")
if(is.empty(opt$ylabel)){
  tryCatch({
    gdxName <- opt$input
    symName <- opt$parameter
    yvar=as_string(sym(colnames(df_p)[2]))
    df_y <- rgdx.set(gdxName, yvar, names=yvar, ts=TRUE)
    yvar_desc = paste(attr(df_y,"ts"), "  ")
  }
  , error = function(ex) { yvar_desc="" ; print(ex) ; print("FAILED to read set description: see above message", call.=FALSE) }
  )
}else{
  yvar_desc = opt$ylabel
}  

# read set z from parameter p2(x,z) if not set by switch -z
zvar_desc <- vector("character")
if(is.empty(opt$zlabel)){
  tryCatch({
    gdxName <- opt$input
    symName <- opt$parameter2
    zvar=as_string(sym(colnames(df_p2)[2]))
    df_z <- rgdx.set(gdxName, zvar, names=zvar, ts=TRUE)
    zvar_desc = paste(attr(df_z,"ts"), "  ")
  }
  , error = function(ex) { zvar_desc="" ; print(ex) ; print("FAILED to read set description: see above message", call.=FALSE) }
  )
}else{
  zvar_desc = opt$zlabel
}  

# store data from gdx
xvar_labels <- unique(df_p[1])
window_end <- nrow(xvar_labels)
if(!is.null(attr(df_p,"ts"))){
  ptitle <- attr(df_p,"ts")
}else{
  ptitle <- symName
}
exec_sys_date=format(Sys.time(), "%Y-%m-%d%Z_%H-%M-%S")
ptitle <- sprintf("%s  %s",ptitle,exec_sys_date)

# check value of input option window 
window_step=0
if (!is.null(opt$window) && !is.na(opt$window)) {
  if(!is.integer(opt$window) || is.na(opt$window) || opt$window<1 ||  opt$window>window_end){
    print(paste("Invalid input: Found",opt$window,"for option window, expected an integer in range 1 to ", window_end))
    print("Additional graphs will not be created")
  }else{
    window_step=opt$window
  }
}

# convert x-axis to numeric
df_p[,1] <- ordered(df_p[,1])
levels(df_p[,1]) <- 1:nrow(unique(df_p[1])) 
df_p[,1] <- as.numeric(as.character(df_p[,1]))

# Prepare plot p(x,y)
xvar <- sym(colnames(df_p)[1])
yvar <- sym(colnames(df_p)[2])
value <- sym(colnames(df_p)[3])
xlabel <- paste(xvar_desc,xvar,"(",xvar_labels[1,1],"=1, ...,",xvar_labels[window_end,1],"=",window_end,")")
ylabel <- paste(yvar_desc,yvar)
nr_colors <- nrow(unique(df_p[2]))
 
# Prepare plot p2(x,z)
nr_shapes <- 0
if(!empty(df_p2)){  
  xvar2 <- sym(colnames(df_p2)[1])
  zvar  <- sym(colnames(df_p2)[2])
  value2 <- sym(colnames(df_p2)[3])
  zlabel <- paste(zvar_desc,zvar)
  if(!identical(levels(df_p_org[,1]),levels(df_p2_org[,1]))){
    stop(paste("Error: index missmatch. Symbols ",value,"and",value2, " must have same indices for factor",xvar))
  }
  nr_shapes <- nrow(unique(df_p2[2]))
  # convert x-axis to numeric
  df_p2[,1] <- ordered(df_p2[,1])
  levels(df_p2[,1]) <- 1:nrow(unique(df_p2[1])) 
  df_p2[,1] <- as.numeric(as.character(df_p2[,1]))
}

#Prepare plot p1 and p2
my_title_font_size = 8
my_axis_title_font_size = 7
my_axis_scale_font_size = 6
my_legend_title_font_size <- 7
my_legend_entry_font_size <- 6
nr_cat <- nr_colors + nr_shapes
if(nr_cat<=8){
  mypalette="Dark2"
} else if(nr_cat<=12){
  mypalette=NULL
  my_legend_title_font_size <- 7
  my_legend_entry_font_size <- 6
}else if(nr_cat<=20) {
  mypalette=NULL
  my_legend_title_font_size <- 4
  my_legend_entry_font_size <- 3
}else{
  mypalette=NULL
  my_legend_title_font_size <- 1
  my_legend_entry_font_size <- 1
}

# plot p(x,y)
df_p_index2_ordered <- fct_reorder2(df_p[,2],df_p[,1],df_p[,3])
g1 <- ggplot() + 
       geom_line(data=df_p, aes(x=!!xvar, y=!!value, group=df_p_index2_ordered, color=df_p_index2_ordered)) +
       labs(colour = value) + ggtitle(ptitle) + xlab(xlabel) + 
       theme(plot.title = element_text(size = my_title_font_size), axis.title=element_text(size=my_axis_title_font_size),
             axis.text = element_text(size = my_axis_scale_font_size), legend.position="bottom", 
             legend.title = element_text(size=my_legend_title_font_size), legend.box = "vertical", 
             legend.text = element_text(size=my_legend_entry_font_size)) +
       guides(color=guide_legend(ncol=3))
if(!is.empty(mypalette)){
  g1 <- g1 +
    scale_color_brewer(palette = mypalette)
}
g2 <- g1

# plot p2(x,z)
if(!empty(df_p2)){
  scaleFactor <- max(df_p[,3]) / max(df_p2[,3])
  df_p2_index2_ordered <- fct_reorder2(df_p2[,2],df_p2[,1],df_p2[,3])
  g2 <- g1 + 
         geom_line(data=df_p2, aes(x=!!xvar2, y=!!value2*scaleFactor, group=df_p2_index2_ordered, linetype=df_p2_index2_ordered)) +
         scale_y_continuous(
          name = paste(value, "-axis. ", ylabel),
          breaks = get_custom_x_axis_breaks(custom_y_axis_tick_distance, max_nr_of_custom_y_axis_ticks, df_p[,3]),
          sec.axis = sec_axis(~./scaleFactor, name=paste(value2, "-axis. ",zlabel)))  + 
         scale_linetype_discrete(name = paste(value2))+
         guides(linetype=guide_legend(ncol=3))
}
g3 <- g2 + scale_x_continuous(breaks = get_custom_x_axis_breaks(custom_x_axis_tick_distance, max_nr_of_custom_x_axis_ticks, df_p[,1]))           
#g3_copy<-g3 # to avoid errors we create a copy, g2 changes with switch -w
#plot(g3_copy)

# create PDF
pdf(file = pdf_name, width = 6.25, height = 4, family = "Times", pointsize = 6, onefile = TRUE)
print(g3)
cnt_plots=1;

# additional figures to PDF with switch -w (window)
if(window_step>=1){
  for(window_curr_start in seq(1, window_end, window_step)){
    window_curr_end = window_curr_start + window_step -1
    if (window_curr_end>window_end){
      window_curr_end=window_end
    }
    xlabel <- paste(xvar_desc,xvar,"(",xvar_labels[window_curr_start,1],"=",window_curr_start,", ...,",xvar_labels[window_curr_end,1],"=",window_curr_end,")")
    g4 <- g2 +xlab(xlabel) + coord_cartesian(xlim = c(window_curr_start,window_curr_end), expand=0)+ 
             scale_x_continuous(breaks = get_custom_x_axis_breaks(custom_x_axis_tick_distance, max_nr_of_custom_x_axis_ticks, df_p[,1], window_step))                 
    print(g4)
    cnt_plots=cnt_plots+1
  }
}
invisible(dev.off())

# create a copy of the plot with switch -a (archive)
if(file.exists(pdf_name)){
  pdf_path=paste(file_path_as_absolute(pdf_name))
  print(sprintf("Rscript created %d figures (%s) see:",cnt_plots, exec_sys_date))
  print(sprintf("%s",pdf_path))
  flush.console()
  if(opt$archive){
    dir_name="archive"
    if(!dir.exists(dir_name)){
      dir.create(dir_name)
    }
    dataPath <- sprintf("%s/%s_%s.pdf",file_path_as_absolute(dir_name),exec_sys_date,symName)
    invisible(file.copy(pdf_name, dataPath, overwrite = TRUE ))
  }  
}else{
  stop("Rscript failed to create PDF")
}
  
