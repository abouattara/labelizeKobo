test_that("labelize_my_data works", {
  df <- data.frame(Q1 = c(1, 2))
  # simulate your label loading
  expect_s3_class(labelize_my_data(df, "fake_path.sps"), "data.frame")
})
