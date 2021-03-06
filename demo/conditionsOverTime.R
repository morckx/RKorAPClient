#!/usr/bin/env Rscript
#
# Plot frequency of an expressions under multiple conditions over time
#
#library(devtools)
#install_git("https://korap.ids-mannheim.de/gerrit/KorAP/RKorAPClient", upgrade="never")
library(RKorAPClient)
library(ggplot2)
library(reshape2)
#library(plotly)

conditionsOverTime <- function(query, conditions, years, kco = new("KorAPConnection", verbose = TRUE)) {
  df = data.frame(year=years)
  for (c in conditions) {
    df[c] <- sapply(df$year, function(y)
      corpusQuery(kco, query, vc=paste(c, "& pubDate in", y))@totalResults)

  }
  df <- melt(df, measure.vars = conditions, value.name = "afreq", variable.name = "condition")
  df$total <- apply(df[,c('year','condition')], 1, function(x) corpusStats(kco, vc=paste(x[2], "& pubDate in", x[1]))@tokens )
  df$ci <- t(sapply(Map(prop.test, df$afreq, df$total), "[[","conf.int"))
  df$freq <- df$afreq / df$total
  g <- ggplot(data = df, mapping = aes(x = year, y = freq, fill=condition, color=condition)) +
    geom_point() +
    geom_line() +
    geom_ribbon(aes(ymin=ci[, 1], ymax=ci[, 2], fill=condition, color=condition), alpha=.3, linetype=0) +
    xlab("TIME") +
    labs(color="Virtual Corpus", fill="Virtual Corpus") +
    ylab(sprintf("Observed frequency of \u201c%s\u201d", query)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))  + scale_x_continuous(breaks=unique(df$year))
  print(g)
  # print(ggplotly(g, tooltip = c("x", "y")))

  df
}

df <- conditionsOverTime("[tt/l=Heuschrecke]", c("textClass = /natur.*/", "textClass=/politik.*/", "textClass=/wirtschaft.*/"), (2002:2018))
#df <- conditionsOverTime("wegen dem [tt/p=NN]", c("textClass = /sport.*/", "textClass=/politik.*/", "textClass=/kultur.*/"), (1995:2005))
