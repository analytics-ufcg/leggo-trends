context("Twitter")

setup <- function() {
  termos_df = readr::read_csv("../../data/tabela_termos.csv") %>%
    head(3)
  return(TRUE)

}


tweets <- leggoTrends::get_tweets_pls(termos_df)

trends <- leggoTrends::generate_twitter_trends(tweets)

test <- function(){

  test_that("get_tweets_pls() returns dataframe", {
    expect_true(is.data.frame(tweets))
  })

  test_that("generate_twitter_trends() returns dataframe", {
    expect_true(is.data.frame(trends))
  })

}
