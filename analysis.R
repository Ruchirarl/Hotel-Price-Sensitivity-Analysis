# --------------------------------------------------------------------------
# Project: Analysis of Hotel Booking Price Sensitivity
# Author: Ruchira
# Date: 2025-09-26
# --------------------------------------------------------------------------

# --- 1. SETUP: LOAD LIBRARIES ---
# Loading all required packages.
library(dplyr)      # For data manipulation (e.g., filter, group_by, summarise)
library(ggplot2)    # For creating high-quality visualizations
library(broom)      # For tidying model output into clean data frames


# --- 2. DATA PREPARATION: LOAD AND CLEAN DATA ---
# Loading the synthetic dataset
hotel_data <- read.csv("synthetic_hotel_data.csv")

# Cleaning column names and creating derived variables for analysis.
hotel_data <- hotel_data %>%
  rename(Booked = `Booked.`) %>%
  # Converting key variables to the correct data types.
  mutate(
    Region = as.factor(Region),
    # Creating income groups from the continuous 'UserIncome' variable for segmented analysis.
    IncomeGroup = cut(UserIncome,
                      breaks = c(-Inf, 40000, 80000, Inf),
                      labels = c("Low", "Medium", "High"))
  )


# --- 3. EXPLORATORY DATA ANALYSIS (EDA) ---

# EDA Part A: Summary Statistics
# Calculating the average booking rate and price by region to spot any high-level differences.
booking_summary_by_region <- hotel_data %>%
  group_by(Region) %>%
  summarise(
    AverageBookingRate = mean(Booked),
    AveragePrice = mean(PricePerNight)
  ) %>%
  arrange(desc(AverageBookingRate))

print("--- Summary: Booking Rate by Region ---")
print(booking_summary_by_region)

# EDA Part B: Visualizations
# Visualizing the distribution of prices to understand its range and frequency.
ggplot(hotel_data, aes(x = PricePerNight)) +
  geom_histogram(bins = 50, fill = "steelblue", color = "white", alpha = 0.8) +
  labs(title = "Distribution of Hotel Prices", x = "Price Per Night ($)", y = "Frequency") +
  theme_minimal()

# Visualizing the core relationship: how price affects booking likelihood, segmented by income.
ggplot(hotel_data, aes(x = PricePerNight, y = Booked, color = IncomeGroup)) +
  geom_smooth(method = "glm", method.args = list(family = "binomial"), se = FALSE) +
  labs(
    title = "Booking Likelihood Decreases as Price Increases",
    subtitle = "This effect varies by customer income group",
    x = "Price Per Night ($)",
    y = "Probability of Booking",
    color = "Income Group"
  ) +
  theme_minimal()


# --- 4. MODELING ---

# Modeling Part A: Predicting Booking Likelihood (Logistic Regression)
# We use a logistic regression model (GLM with family="binomial") because the outcome
# is binary (0 for no, 1 for yes). This model estimates how each predictor affects the
# probability of a customer booking.
booking_model <- glm(Booked ~ PricePerNight * IncomeGroup + Region,
                     data = hotel_data,
                     family = "binomial")

print("--- Summary of Booking Likelihood Model (GLM) ---")
print(tidy(booking_model))


# Modeling Part B: Predicting Number of Nights Booked (Linear Regression)
# This model focuses only on successful bookings to see what factors influence the length of stay.
# First, we filter the dataset to include only customers who booked.
bookings_only <- hotel_data %>%
  filter(Booked == 1)

# Now, we build a standard linear model (LM) because 'Nights' is a continuous variable.
nights_model <- lm(Nights ~ PricePerNight + IncomeGroup + Region, data = bookings_only)

print("--- Summary of Nights Booked Model (LM) ---")
print(tidy(nights_model))


# --- 5. VISUALIZING MODEL PREDICTIONS ---
# This plot shows the relationship the model has learned between price and booking probability
# for each income group, holding other factors constant.
hotel_data$PredictedBookingProb <- predict(booking_model, newdata = hotel_data, type = "response")

ggplot(hotel_data, aes(x = PricePerNight, y = PredictedBookingProb, color = IncomeGroup)) +
  geom_line(aes(group = IncomeGroup), size = 1) +
  labs(
    title = "Model Predictions: Price Sensitivity by Income Group",
    subtitle = "Shows the learned relationship between price and booking probability",
    x = "Price Per Night ($)",
    y = "Predicted Probability of Booking",
    color = "Income Group"
  ) +
  theme_minimal()

# --- END OF SCRIPT ---