#' Get a list of beta, vcov, df and sigma from a protLM object
#'
#' @description This function returns a list with length equal to a \code{\link[=protLM-class]{protLM}} object supplied as input.
#' Each element of this list corresponds to a model in the \code{\link[=protLM-class]{protLM}} object and contains in itself a list holding the parameter estimates \code{beta}, the variance-covariance matrix \code{vcov},
#' the residual degrees of freedom \code{df} and the residual standard deviation \code{sigma} for this model.
#' For mixed models, the variance covariance matrix is bias-adjusted, the degrees of freedom are calculated as the trace of the Hat matrix (Ruppert et al., 2003).
#' @param protLM An object of class \code{\link[=protLM-class]{protLM}}.
#' @param exp_unit The effect that in all models corresponds to the experimental unit. Only needed when one would like to calculate a more conservative way of estimating the degrees of freedom.
#' The default way of estimating the degrees of freedom (\code{exp_unit=NULL}) subtracts the total number of observations by the trace of the Hat matrix. However, often, observations are not completely independent. A more conservative way (\code{df_exp}) is defining on which level the treatments were executed and substracting all degrees of freedom lost due to between-treatement effects (\code{pars_df}) from the number of treatments.
#' @param pars_df Only used if exp_unit is not \code{NULL}. Character vector indicating all parameters in the models that are between-treatment effects in order to calculate a more conservative degrees of freedom (\code{df_exp}). If left to default (\code{NULL}), all parameters in the models will be asumed to be between-treatment effects (this is not adviced as the result will mostly be too conservative).
#' @param subset .......
#' @return A list with length equal to the \code{models} object containing list with four elements: (1) a named column matrix \code{beta} containing the parameter estimates, (2) a named square variance-covariance matrix \code{vcov}, (3) a numeric value \code{df} equal to the residual degrees of freedom and (4) a numeric value \code{sigma} equal to the residual standard deviation of the model.
#' @examples #Load the protLM object protmodel:
#' data(modelRRCPTAC, package="MSqRob")
#' betaVcovDfList <- getBetaVcovDfList(getModels(modelRRCPTAC[1:10], simplify=FALSE))
#' betaVcovDfList
#' @references David Ruppert, M.P. Want and R.J. Carroll.
#' Semiparametric Regression.
#'  Cambridge University Press, 2003.
#' @include protdata.R
#' @include protLM.R
#' @include getBetaVcovDf.R
#' @include squeezeVarRob.R
#' @export
getBetaVcovDfList <- function(protLM, exp_unit=NULL, pars_df=NULL, subset=NULL)
{

  #List of models:
  models <- getModels(protLM, simplify=FALSE)
  #Types of models: either "lmerMod" or "lm":
  classes <- sapply(models, "class")

  if(length(models)!=length(classes)){stop("models and classes vectors should be of the same length.")}

  betaVcovDfList <- vector("list", length(models))

  for(i in 1:length(classes))
  {
    if(classes[i] %in% c("lm","lmerMod"))  {
      betaVcovDfList[[i]] <- getBetaVcovDf(models[[i]], exp_unit=exp_unit, pars_df=pars_df, subset=subset)
    } else{
      betaVcovDfList[[i]] <- NULL
      warning(paste0("classes[",i,"] is not equal to \"lm\" or \"lmerMod\". Returning NULL."))
    }
  }

  names(betaVcovDfList) <- getAccessions(protLM)

  return(betaVcovDfList)
}