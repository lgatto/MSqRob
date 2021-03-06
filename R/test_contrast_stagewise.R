#' Perform stage-wise contrast testing
#'
#' @description A shortcut version for contrast testing and multiple testing correction using first \code{\link{test.contrast_adjust}} to perform an ANOVA as a first stage.
#' In the second stage, the functions \code{\link{test.protLMcontrast}}, \code{\link{prot.p.adjust_protwise}} and \code{\link{prot.signif}} are used sequentially only on the proteins retained in the first stage.
#' This approach is more powerful than the classic \code{\link{test.contrast_adjust}} when testing for contrasts where related proteins are expected to be differentially abundant. This approach is also better for identifying interactions.
#' @param protLM An object of class \code{\link[=protLM-class]{protLM}}.
#' @param L A contrast matrix with the parameter levels as rows and a column for each contrast.
#' @param level	The significance level at which the q-value needs to be controlled. Defaults to 5\%.
#' @param method_stage1 Correction method to be used in the first stage ANOVA. Can be abbreviated. Defaults to "fdr". To get all available methods, type \code{p.adjust.methods}. For more information on these methods, see the \code{\link{p.adjust}} function.
#' @param add.annotations A logical indicating whether the \code{annotations} slot of the \code{\link[=protLM-class]{protLM}} object should be added as extra columns to each matrix in the returned list of matrices. Defaults to \code{TRUE}.
#' @param simplify A logical indicating wheter, if there is only one contrast, a matrix should be returned instead of a list containing one matrix. Defaults to \code{TRUE}.
#' @param lfc The minimum (log2) fold-change that is considered scientifically meaningful. Defaults to \code{0}. Ignored when \code{anova = TRUE}.
#' @param type_dfs Either one of \code{"residual"}, \code{"between-within"}, \code{"Satterthwaite"}, \code{"exp_between"} or \code{"custom"}. This argument indicates how the degrees of freedom should be calculated. Defaults to \code{"residual"}.
#' More information is given under 'Details'.
#' @param custom_dfsS1 Only used if \code{type_dfs="custom"}. A list of length equal to the number of models in \code{protLM} containing numeric values representing the degrees of freedom that should be used for each model in the \code{protLM} object during the anova test in stage 1. Defaults to \code{NULL}.
#' @param custom_dfsS2 Only used if \code{type_dfs="custom"}. A list of length equal to the number of models in \code{protLM} containing vectors of lenght \code{ncol(L)} representing the degrees of freedom that should be used for each contrast in \code{L} and each model in the \code{protLM} object during stage 2. Defaults to \code{NULL}.
#' @param exp_unit Only used if \code{type_dfs="exp_between"}. The effect that in all models corresponds to the experimental unit.
#' @param pars_between Only used if \code{type_dfs="exp_between"}. Character vector indicating all parameters in the models that are between-treatment effects. If left to default (\code{NULL}), all parameters in the models will be asumed to be between-treatment effects (this is not adviced as the result will mostly be too conservative).
#' @param printProgress A logical indicating whether the R should print a message before calculating the contrasts for each accession. Defaults to \code{FALSE}.
#' @param shiny A logical indicating whether this function is being used by a Shiny app. Setting this to \code{TRUE} only works when using this function in a Shiny app and allows for dynamic progress bars. Defaults to \code{FALSE}.
#' @param message_extractS1 Only used when \code{printProgress=TRUE} and \code{shiny=TRUE}. A single-element character vector: the message to be displayed to the user during the extraction of beta, vcov, df and sigma during stage 1, or \code{NULL} to hide the current message (if any).
#' @param message_testS1 Only used when \code{printProgress=TRUE} and \code{shiny=TRUE}. A single-element character vector: the message to be displayed to the user during the testing of the contrasts during stage 1, or \code{NULL} to hide the current message (if any).
#' @param message_extractS2 Only used when \code{printProgress=TRUE} and \code{shiny=TRUE}. A single-element character vector: the message to be displayed to the user during the extraction of beta during stage 2, vcov, df and sigma, or \code{NULL} to hide the current message (if any).
#' @param message_testS2 Only used when \code{printProgress=TRUE} and \code{shiny=TRUE}. A single-element character vector: the message to be displayed to the user during the testing of the contrasts during stage 2, or \code{NULL} to hide the current message (if any).
#' @details Calculating degrees of freedom (and hence p values) for mixed models with unbalanced designs is an unresolved issue in the field (see for example here https://stat.ethz.ch/pipermail/r-help/2006-May/094765.html and here https://stat.ethz.ch/pipermail/r-sig-mixed-models/2008q2/000904.html).
#' We offer different approximations and leave it up to the user to select his/her preferred approach.
#' \code{"residual"} calculates approximative degrees of freedom by subtracting the trace of the hat matrix from the number of observations. It is the default setting, but this approach might be somewhat too liberal.
#' \code{"Satterthwaite"} calculates approximative degrees of freedom using Satterthwaite's approximation (Satterthwaite, 1946). This approximative approach is used in many applications but is rather slow to calculate and might lead to some missing values due difficulties in calculating the Hessian.
#' \code{"exp_between"} calculates approximative degrees of freedom by defining on which level the treatments were executed and substracting all degrees of freedom lost due to between-treatement effects (\code{pars_between}) from the number of experimental units \code{exp_unit}. This allows to mimick the behaviour of \code{type_dfs="between-within"} for more complex designs.
#' \code{"custom"} Allows the user to provide his/her own degrees of freedom for each contrast and each protein. Custom degrees of freedom should be entered in the \code{custom_dfs} field.
#' @return A list of matrices, with each matrix in the list corresponding to a contrast in \code{L}. Each row of the matrix corresponds to a protein in the \code{\link[=protLM-class]{protLM}} object.
#' The \code{estimate} column contains the size estimate of the contrast, the \code{se} column contains the estimated standard error on the contrast, the \code{Tval} column contains the T-value corresponding to the contrast, the \code{pval} column holds the p-value corresponding to the contrast and the \code{qval} column holds the corrected p-values.
#' Each matrix is sorted from smalles to largest \code{pval} with \code{NA} values at the bottom of the matrices.
#' If \code{simplify=TRUE} and the \code{\link[=protLM-class]{protLM}} object contains only one element, the matrix is not present in a list.
#' @include testProtLMContrast.R
#' @include updateProgress.R
#' @include prot_p_adjust.R
#' @include prot_signif.R
#' @include test_contrast_adjust.R
#' @include prot_p_adjust_protwise.R
#' @export
test.contrast_stagewise <- function(protLM, L, level=0.05, method_stage1="fdr", add.annotations=TRUE, simplify=TRUE, lfc=0, type_dfs="residual", custom_dfsS1=NULL, custom_dfsS2=NULL, exp_unit=NULL, pars_between=NULL, printProgress=FALSE, shiny=FALSE, message_extractS1=NULL, message_testS1=NULL, message_extractS2=NULL, message_testS2=NULL)
{

  contrast_S1 <- test.contrast_adjust(protLM, L, level=level, method=method_stage1, add.annotations=add.annotations, simplify=TRUE, lfc=lfc, anova=TRUE, anova.na.ignore=TRUE, type_dfs=type_dfs, custom_dfs=custom_dfsS1, exp_unit=exp_unit, pars_between=pars_between, printProgress=printProgress, shiny=shiny, message_extract=message_extractS1, message_test=message_testS1)

  #Extract the ones that are significant in stage 1
  sign_setS1 <- subset(contrast_S1, contrast_S1[,"signif"]==1)
  significantS1 <- rownames(sign_setS1)

  contrasts <- test.protLMcontrast(protLM, L, add.annotations=add.annotations, simplify=FALSE, lfc=lfc, type_dfs=type_dfs, custom_dfs=custom_dfsS2, exp_unit=exp_unit, pars_between=pars_between, printProgress=printProgress, shiny=shiny, message_extract=message_extractS2, message_test=message_testS2)

  n_ann <- ncol(getAnnotations(protLM))

  contrasts <- lapply(contrasts, function(x){
    #Order each matrix according to the first stage
    x <- x[match(rownames(contrast_S1), rownames(x)),]
    #Add the pval, qval and signif columns of the first stage at the appropriate place in the data frame
    x <- data.frame(x[,1:(4+n_ann)],pvalS1=contrast_S1[,"pval"],qvalS1=contrast_S1[,"qval"],signifS1=contrast_S1[,"signif"],pval=x[,(5+n_ann)])
    return(x)})

  contrasts <- prot.p.adjust_protwise(contrasts, L, stage2=TRUE, significant_stage1=significantS1)
  contrasts <- prot.signif(contrasts, level=level)

  #Add the results of the ANOVA
  contrasts$ANOVA <- contrast_S1

  if(isTRUE(simplify) & length(contrasts)==1)
  {
    contrasts <- contrasts[[1]]
  }

  return(contrasts)
}
