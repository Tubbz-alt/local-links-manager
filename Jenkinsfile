#!/usr/bin/env groovy

library("govuk")

node("postgresql-9.3") {
  govuk.buildProject(brakeman: true, rubyLintDiff: false)
}
