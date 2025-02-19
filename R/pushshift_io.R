#' Get data from pushshift.io
#'
#' Reads/parses reddit data from api.pushshift.io
#'
#' @param subreddit Name of subreddit from which to get data. Defaults to "all".
#' @param n Number of submission/posts to return. Defaults to 100.
#' @param query A search query. By default, there is no search query.
#' @param after Optional, the date-time from which to start the next search.
#' @param before Optional, the date-time from which to start the next search.
#' @return A data frame of reddit data.
#' @details Column descriptions are provided below
#'
#' \itemize{
#'   \item author Name of author of post
#'   \item author_flair_css_class Flair class attribute
#'   \item author_flair_text Flair text
#'   \item created_utc Date-time in UTC timezone
#'   \item domain Domain
#'   \item full_link Full URL
#'   \item id Unique identifier string
#'   \item is_self Whether is self
#'   \item link_flair_css_class Flair class attribute for link
#'   \item link_flair_text Flair text for link
#'   \item num_comments Number of comments
#'   \item over_18 Whether material is intended for people over 18
#'   \item permalink Stable link
#'   \item post_hint Type of post
#'   \item retrieved_on Date-time when data was originally received
#'   \item subreddit Name of subreddit
#'   \item score Reddit score
#'   \item selftext Text
#'   \item stickied Whether it's been stickied
#'   \item subreddit Name of subreddit
#'   \item subreddit_id Unique identifier of subreddit
#'   \item thumbnail Path to post thumbnail
#'   \item title Title of post
#'   \item url URL
#' }
#'
#' @export
#' @import jtools
get_reddit_posts <- function(subreddit = "all", query = NULL, n = 100,
                             after = NULL, before = NULL) {
  n <- ceiling(n / 100)
  x <- vector("list", n)
  for (i in seq_along(x)) {
    url <- "https://api.pushshift.io/reddit/search/submission/?size=100&sort=desc"
    if (!identical(subreddit, "all")) {
      url <- paste0(url, "&subreddit=", subreddit)
    }
    if (!is.null(before)) {
      url <- paste0(url, "&before=", as.numeric(as.POSIXct(before)))
    }
    if (!is.null(after)) {
      url <- paste0(url, "&after=", as.numeric(as.POSIXct(after)))
    }
    if (!is.null(query)) {
      url <- paste0(url, "&q=", xml2::url_escape(query))
    }
    r <- httr::RETRY("GET", url, encode = "json", times = 5, pause_base = 10,
                     quiet = FALSE)
    j <- httr::content(r, as = "text", encoding = "UTF-8")
    j <- jsonlite::fromJSON(j)
    x[[i]] <- as_tbl(non_recs(j$data))
    if (!"created_utc" %in% names(x[[i]])) break
    x[[i]] <- formate_createds(x[[i]])
    before <- min(x[[i]]$created_utc)
    if (length(before) == 0) break
    print_complete(
      "#", i, ": collected ", nrow(x[[i]]), " posts"
    )
  }
  x <- lapply(x, function(x) {
    if (!"created_utc" %in% names(x)) NULL else x
    })
  out <- tryCatch(docall_rbind(x),
    error = function(e) x)
  key_names <- c("id", "subreddit", "created_utc", "author", "title", "score",
                 "selftext", "full_link", "num_comments")
  names_order <- c(key_names, names(out) %not% key_names)
  out <- out[names_order]
  out$selftext[!out$is_self] <- NA
  out
}


#' Get comments from pushshift.io
#'
#' Reads/parses reddit data from api.pushshift.io
#'
#' @param subreddit Name of subreddit from which to get data. Defaults to "all".
#' @param author Restrict results to author.
#' @param n Number of submission/posts to return. Defaults to 1000.
#' @param after Optional, the date-time from which to start the next search.
#' @param before Optional, the date-time from which to start the next search.
#' @inheritParams get_reddit_posts
#' @return A data frame of reddit data.
#' @details Column descriptions are provided below
#'
#' \itemize{
#'   \item author Name of author of post
#'   \item author_flair_css_class Flair class attribute
#'   \item author_flair_text Flair text
#'   \item body Text of the comment
#'   \item created_utc Date-time in UTC timezone
#'   \item domain Domain
#'   \item full_link Full URL
#'   \item id Unique identifier string
#'   \item is_self Whether is self
#'   \item link_flair_css_class Flair class attribute for link
#'   \item link_flair_text Flair text for link
#'   \item num_comments Number of comments
#'   \item over_18 Whether material is intended for people over 18
#'   \item permalink Stable link
#'   \item post_hint Type of post
#'   \item retrieved_on Date-time when data was originally received
#'   \item subreddit Name of subreddit
#'   \item score Reddit score
#'   \item selftext Text
#'   \item stickied Whether it's been stickied
#'   \item subreddit Name of subreddit
#'   \item subreddit_id Unique identifier of subreddit
#'   \item thumbnail Path to post thumbnail
#'   \item title Title of post
#'   \item url URL
#' }
#'
#' @export
get_reddit_comments <- function(subreddit = "all", query = NULL, author = NULL,
                                n = 100, before = NULL, after = NULL) {
  n <- ceiling(n / 100)
  x <- vector("list", n)
  for (i in seq_along(x)) {
    url <- "https://api.pushshift.io/reddit/search/comment/?size=100&sort=desc"
    if (!identical(subreddit, "all")) {
      url <- paste0(url, "&subreddit=", subreddit)
    }
    if (!is.null(before)) {
      url <- paste0(url, "&before=", as.numeric(as.POSIXct(before)))
    }
    if (!is.null(after)) {
      url <- paste0(url, "&after=", as.numeric(as.POSIXct(after)))
    }
    if (!is.null(author)) {
      url <- paste0(url, "&author=", author)
    }
    if (!is.null(query)) {
      url <- paste0(url, "&q=", xml2::url_escape(query))
    }
    r <- httr::RETRY("GET", url, encode = "json", times = 5, pause_base = 10,
                     quiet = FALSE)
    j <- httr::content(r, as = "text", encoding = "UTF-8")
    j <- jsonlite::fromJSON(j)
    x[[i]] <- as_tbl(non_recs(j$data))
    if (!"created_utc" %in% names(x[[i]])) break
    x[[i]] <- formate_createds(x[[i]])
    before <- min(x[[i]]$created_utc)
    if (length(before) == 0) break
    print_complete(
      "#", i, ": collected ", nrow(x[[i]]), " posts"
    )
  }
  out <- tryCatch(docall_rbind(x),
                  error = function(e) x)
  key_names <- c("id", "parent_id", "subreddit", "created_utc", "author",
                 "score", "body")
  names_order <- c(key_names, names(out) %not% key_names)
  out <- out[names_order]
  out
}

