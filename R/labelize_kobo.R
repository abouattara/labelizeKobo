#' Transform a vector of label lines into a single text block
#'
#' @param input_vector A character vector containing label lines
#' @return A single string with newline-separated labels
#' @export
#'
transform_to_label_text <- function(input_vector) {
  # Initialize an empty string to store the result
  label_text <- ""

  # Loop through the vector
  for (i in seq_along(input_vector)) {
    # Add the current element followed by a newline
    label_text <- paste0(label_text, input_vector[i], "\n")
  }

  return(label_text)
}



#' Parse label text and return a list of value labels by variable
#'
#' @param label_text A character vector of lines containing labels
#' @return A named list: each element is a list of value-label pairs for a variable
#' @export
#'
parser_labels <- function(label_text){
  lines=label_text
  lines[2] = paste0("/",lines[2])
  labels_map <- list()  ## Dictionnaire pour stocker les labels par variable
  current_variable <- NULL

  for (line in lines) {
    line <- str_trim(line)  ## Nettoyer les espaces en début et fin de ligne

    ## Si la ligne commence par une variable (/Q1.02, /consent, etc.)
    if (str_starts(line, "/")) {
      ## Extraire le nom de la variable
      current_variable <- str_remove(line, "^/")
      labels_map[[current_variable]] <- list()  ## Initialiser la liste des valeurs pour cette variable
    }
    ## Sinon, la ligne contient une paire valeur-label
    else if (str_detect(line, "' '")) {
      ## Extraire la paire valeur-label
      parts <- strsplit(line, "' '")[[1]]
      value <- gsub("'", "", parts[1])
      label <- gsub("'", "", parts[2])

      ## Ajouter la paire au dictionnaire pour la variable courante
      if (!is.null(current_variable)) {
        labels_map[[current_variable]][[value]] <- label
      }
    }
  }

  return(labels_map)
}


#' Process SPSS .sps label file
#'
#' @param file_path Path to the .sps file
#' @return A list with `valueLabel` (character vector) and `labels_df` (data frame of variable labels)
#' @export
#'
process_sps_file <- function(file_path) {
  # Read .sps file as text lines (not as CSV!)
  script_sps <- readr::read_lines(file_path)

  # Remove leading/trailing whitespace
  cleaned_labels <- trimws(script_sps)

  # Find the index of the first "." line (separator)
  index <- which(cleaned_labels == ".")[1]

  # Extract value labels (everything after ".")
  valueLabel <- cleaned_labels[(index + 1):length(cleaned_labels)]

  # Extract VARIABLE LABELS section (lines starting with "/")
  labels_lines <- grep("^/", cleaned_labels, value = TRUE)

  # Parse variable names and descriptions
  labels <- gsub("^/([^ ]+) '(.*)'", "\\1", labels_lines)
  descriptions <- gsub("^/([^ ]+) '(.*)'", "\\2", labels_lines)

  # Create data frame
  labels_df <- data.frame(
    variable = labels,
    description = descriptions,
    stringsAsFactors = FALSE
  )

  # Return result
  return(list(valueLabel = valueLabel, labels_df = labels_df))
}



#' Labelize variable with SPSS .sps label
#'
#' @param data Unlabel data read in R
#' @param spsFilePath Path to the .sps file
#' @return A dataframe `data` (data frame with variables labelled)
#' @export
labeliser_variables <- function(data, spsFilePath) {
  process = process_sps_file(spsFilePath)
  labels_map=parser_labels(process$valueLabel)
  for (variable in names(labels_map)) {
    if (variable %in% colnames(data)) {
      ## Si la colonne existe et est numérique
      data[[variable]] <- case_when(
        data[[variable]] %in% names(labels_map[[variable]]) ~
          as.character(labels_map[[variable]][as.character(data[[variable]])]),
        TRUE ~ as.character(data[[variable]])  ## Garde les valeurs d'origine si aucune correspondance
      )
    }
  }
  return(data)
}


#' Aplly SPSS .sps label to variable modality name coded
#'
#' @param data Unlabel value label data read in R
#' @param spsFilePath Path to the .sps file
#' @return A dataframe `data` (data frame with variables labelled)
#' @export
apply_labels <- function(data, spsFilePath) {
  process = process_sps_file(spsFilePath)
  labels_df= process$labels_df
  ## Parcours des lignes de labels_df
  for (i in 1:nrow(labels_df)) {
    var_name <- labels_df$variable[i]
    var_label <- labels_df$description[i]

    ## Vérifier si la variable existe dans le jeu de données
    if (var_name %in% colnames(data)) {
      ## Appliquer le label à la variable
      var_label(data[[var_name]]) <- var_label
    }
  }

  ## Retourner le jeu de données avec les labels appliqués
  return(data)
}



#' labelize kobotoolbox,ODK, ONA data to data labelled including answers code and variable label
#'
#' @param unlabel.data : unlabel data (it may be a dataframe)
#' @param labelfile.path : label file path (.sps)
#' @return A dataframe `data` (data frame with variables and modalities labelled)
#' @export
labelize_my_data <- function(unlabel.data, labelfile.path){
  data <- labeliser_variables(unlabel.data, labelfile.path)
  data = apply_labels(data, labelfile.path)
  names(data) = gsub("[./]", "_", names(data))
  return(data)
}
