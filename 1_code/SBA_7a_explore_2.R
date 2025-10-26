
# Setup ------------------------------------------------------------------------

library('tidyverse')

path <- '/Users/indermajumdar/Downloads/sba_7a'

##############
#Load Data
##############

loans <- tibble()

loansdir <- dir(path)

for (file in loansdir) {
  temp <- read.csv(paste(path, file, sep = "/"))
  loans <- rbind(loans, temp)
}


library(tidyverse)
library(lubridate)   # you use year()
library(scales)      # label_dollar, label_percent, pretty_breaks

# --- Minimal, clean theme
theme_im <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.caption.position = "plot",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_line(linewidth = 0.3),
      panel.grid.major.y = element_line(linewidth = 0.3),
      legend.position = "top",
      legend.title = element_text(face = "bold"),
      plot.title = element_text(face = "bold"),
      axis.title = element_text(face = "bold")
    )
}

# --- Helper to save with consistent spec
save_fig <- function(p, filename, w = 7, h = 4.2, dpi = 320) {
  ggsave(filename, p, width = w, height = h, dpi = dpi, bg = "white")
}

# Dates
loans$ApprovalDate <- as.Date(loans$ApprovalDate, format = "%m/%d/%Y")

# Numeric amounts (handles "12,345", "$12,345.67")
loans <- loans |>
  mutate(
    GrossApproval         = readr::parse_number(as.character(GrossApproval),         na = c("", "NA", "None")),
    SBAGuaranteedApproval = readr::parse_number(as.character(SBAGuaranteedApproval), na = c("", "NA", "None")),
    InitialInterestRate   = readr::parse_number(as.character(InitialInterestRate),   na = c("", "NA", "None"))
  )

loanamounts <- loans |>
  filter(BorrState == "WI") |>
  mutate(ApprovalYear = year(ApprovalDate)) |>
  group_by(ApprovalYear) |>
  summarise(
    loan_count   = n(),
    non_wi_count = sum(BankState != "WI", na.rm = TRUE),
    share_non_wi = non_wi_count / loan_count,
    .groups = "drop"
  )

# Plot: counts
p_counts <- ggplot(loanamounts, aes(x = ApprovalYear)) +
  geom_line(aes(y = loan_count, linetype = "Total loans"), linewidth = 0.9) +
  geom_line(aes(y = non_wi_count, linetype = "Loans by non-WI banks"), linewidth = 0.9) +
  scale_linetype_manual(values = c("Total loans" = "solid", "Loans by non-WI banks" = "dashed"), name = NULL) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "SBA 7(a) Loans to WI Borrowers: Count per Year",
    subtitle = "Comparing all lenders vs. lenders headquartered outside Wisconsin",
    x = "Approval year",
    y = "Number of loans",
    caption = "Source: SBA 7(a) FOIA; Fields: BorrState, BankState, ApprovalDate"
  ) +
  theme_im()
p_counts
# save_fig(p_counts, "fig_counts_total_vs_nonWI.png")

# Plot: share
p_count_share <- ggplot(loanamounts, aes(x = ApprovalYear, y = share_non_wi)) +
  geom_line(linewidth = 0.9) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Share of WI Borrower Loans Originated by Non-WI Banks",
    x = "Approval year",
    y = "Share of loans",
    caption = "Source: SBA 7(a) FOIA; Fields: BorrState, BankState, ApprovalDate"
  ) +
  theme_im()
p_count_share
# save_fig(p_count_share, "fig_share_count_nonWI.png")

loanvolumes <- loans |>
  filter(BorrState == "WI") |>
  mutate(ApprovalYear = year(ApprovalDate)) |>
  group_by(ApprovalYear) |>
  summarise(
    loan_total   = sum(GrossApproval, na.rm = TRUE),
    non_wi_vol   = sum(GrossApproval[BankState != "WI"], na.rm = TRUE),
    share_non_wi = non_wi_vol / loan_total,
    .groups = "drop"
  )

# Plot: volumes
p_vol <- ggplot(loanvolumes, aes(x = ApprovalYear)) +
  geom_line(aes(y = loan_total, linetype = "Total $ volume"), linewidth = 0.9) +
  geom_line(aes(y = non_wi_vol, linetype = "Non-WI bank $ volume"), linewidth = 0.9) +
  scale_linetype_manual(values = c("Total $ volume" = "solid", "Non-WI bank $ volume" = "dashed"), name = NULL) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_dollar(scale = 1, accuracy = 1)) +
  labs(
    title = "SBA 7(a) Approved Dollars to WI Borrowers: Volume per Year",
    subtitle = "Total vs. volume from banks headquartered outside Wisconsin",
    x = "Approval year",
    y = "Approved dollars",
    caption = "Source: SBA 7(a) FOIA; Fields: GrossApproval, BorrState, BankState, ApprovalDate"
  ) +
  theme_im()
p_vol
# save_fig(p_vol, "fig_volume_total_vs_nonWI.png")

# Plot: share of volume
p_vol_share <- ggplot(loanvolumes, aes(x = ApprovalYear, y = share_non_wi)) +
  geom_line(linewidth = 0.9) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Share of Approved Dollars from Non-WI Banks",
    x = "Approval year",
    y = "Share of approved dollars",
    caption = "Source: SBA 7(a) FOIA; Fields: GrossApproval, BankState"
  ) +
  theme_im()
p_vol_share
# save_fig(p_vol_share, "fig_share_volume_nonWI.png")

loanvolumes <- loans |>
  filter(BorrState == "WI") |>
  mutate(ApprovalYear = year(ApprovalDate)) |>
  group_by(ApprovalYear) |>
  summarise(
    loan_total   = sum(GrossApproval, na.rm = TRUE),
    non_wi_vol   = sum(GrossApproval[BankState != "WI"], na.rm = TRUE),
    share_non_wi = non_wi_vol / loan_total,
    .groups = "drop"
  )

# Plot: volumes
p_vol <- ggplot(loanvolumes, aes(x = ApprovalYear)) +
  geom_line(aes(y = loan_total, linetype = "Total $ volume"), linewidth = 0.9) +
  geom_line(aes(y = non_wi_vol, linetype = "Non-WI bank $ volume"), linewidth = 0.9) +
  scale_linetype_manual(values = c("Total $ volume" = "solid", "Non-WI bank $ volume" = "dashed"), name = NULL) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_dollar(scale = 1, accuracy = 1)) +
  labs(
    title = "SBA 7(a) Approved Dollars to WI Borrowers: Volume per Year",
    subtitle = "Total vs. volume from banks headquartered outside Wisconsin",
    x = "Approval year",
    y = "Approved dollars",
    caption = "Source: SBA 7(a) FOIA; Fields: GrossApproval, BorrState, BankState, ApprovalDate"
  ) +
  theme_im()
p_vol
# save_fig(p_vol, "fig_volume_total_vs_nonWI.png")

# Plot: share of volume
p_vol_share <- ggplot(loanvolumes, aes(x = ApprovalYear, y = share_non_wi)) +
  geom_line(linewidth = 0.9) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Share of Approved Dollars from Non-WI Banks",
    x = "Approval year",
    y = "Share of approved dollars",
    caption = "Source: SBA 7(a) FOIA; Fields: GrossApproval, BankState"
  ) +
  theme_im()
p_vol_share
# save_fig(p_vol_share, "fig_share_volume_nonWI.png")

ts <- loans |>
  filter(BorrState == "WI") |>
  mutate(ApprovalYear = year(ApprovalDate)) |>
  group_by(ApprovalYear) |>
  summarise(
    n      = n(),
    mean   = mean(GrossApproval, na.rm = TRUE),
    median = median(GrossApproval, na.rm = TRUE),
    p25    = quantile(GrossApproval, 0.25, na.rm = TRUE),
    p75    = quantile(GrossApproval, 0.75, na.rm = TRUE),
    sd     = sd(GrossApproval, na.rm = TRUE),
    se     = sd / sqrt(n),
    tcrit  = ifelse(n > 1, qt(0.975, df = n - 1), NA_real_),
    ci_lo  = mean - tcrit * se,
    ci_hi  = mean + tcrit * se,
    .groups = "drop"
  )

p_amt_dist <- ggplot(ts, aes(x = ApprovalYear)) +
  geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.18, fill = "grey70") +
  geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
  geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
  geom_point(aes(y = median), size = 1.3) +
  geom_point(aes(y = mean),   size = 1.3) +
  scale_linetype_manual(values = c("Median" = "dashed", "Mean" = "solid"), name = NULL) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_dollar(accuracy = 1)) +
  labs(
    title = "Approved Dollars per Loan (WI borrowers)",
    subtitle = "Interquartile band with mean and median",
    x = "Approval year",
    y = "Dollars per loan",
    caption = "Source: SBA 7(a) FOIA; Field: GrossApproval"
  ) +
  theme_im()
p_amt_dist
# save_fig(p_amt_dist, "fig_amount_per_loan_allWI.png")

ts <- loans |>
  filter(BorrState == "WI", !is.na(InitialInterestRate), InitialInterestRate != 0) |>
  mutate(ApprovalYear = year(ApprovalDate)) |>
  group_by(ApprovalYear) |>
  summarise(
    n      = n(),
    mean   = mean(InitialInterestRate, na.rm = TRUE),
    median = median(InitialInterestRate, na.rm = TRUE),
    p25    = quantile(InitialInterestRate, 0.25, na.rm = TRUE),
    p75    = quantile(InitialInterestRate, 0.75, na.rm = TRUE),
    sd     = sd(InitialInterestRate, na.rm = TRUE),
    se     = sd / sqrt(n),
    tcrit  = ifelse(n > 1, qt(0.975, df = n - 1), NA_real_),
    ci_lo  = mean - tcrit * se,
    ci_hi  = mean + tcrit * se,
    .groups = "drop"
  )

p_rate <- ggplot(ts, aes(x = ApprovalYear)) +
  geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.18, fill = "grey70") +
  geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
  geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
  geom_point(aes(y = median), size = 1.3) +
  geom_point(aes(y = mean),   size = 1.3) +
  scale_linetype_manual(values = c("Median" = "dashed", "Mean" = "solid"), name = NULL) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_number(accuracy = 0.1), limits = function(z) c(floor(min(z, na.rm=TRUE)), ceiling(max(z, na.rm=TRUE)))) +
  labs(
    title = "Initial Interest Rates on SBA 7(a) Loans (WI borrowers)",
    subtitle = "Interquartile band with mean and median",
    x = "Approval year",
    y = "Percent",
    caption = "Source: SBA 7(a) FOIA; Field: InitialInterestRate"
  ) +
  theme_im()
p_rate
# save_fig(p_rate, "fig_rates_allWI.png")

ts <- loans |>
  filter(BorrState == "WI", !is.na(InitialInterestRate), InitialInterestRate != 0, CollateralInd == "N") |>
  mutate(ApprovalYear = year(ApprovalDate)) |>
  group_by(ApprovalYear) |>
  summarise(
    n      = n(),
    mean   = mean(InitialInterestRate, na.rm = TRUE),
    median = median(InitialInterestRate, na.rm = TRUE),
    p25    = quantile(InitialInterestRate, 0.25, na.rm = TRUE),
    p75    = quantile(InitialInterestRate, 0.75, na.rm = TRUE),
    sd     = sd(InitialInterestRate, na.rm = TRUE),
    se     = sd / sqrt(n),
    tcrit  = ifelse(n > 1, qt(0.975, df = n - 1), NA_real_),
    ci_lo  = mean - tcrit * se,
    ci_hi  = mean + tcrit * se,
    .groups = "drop"
  )

p_rate_collateral <- ggplot(ts, aes(x = ApprovalYear)) +
  geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.18, fill = "grey70") +
  geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
  geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
  geom_point(aes(y = median), size = 1.3) +
  geom_point(aes(y = mean),   size = 1.3) +
  scale_linetype_manual(values = c("Median" = "dashed", "Mean" = "solid"), name = NULL) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_number(accuracy = 0.1), limits = function(z) c(floor(min(z, na.rm=TRUE)), ceiling(max(z, na.rm=TRUE)))) +
  labs(
    title = "Initial Interest Rates on SBA 7(a) Loans (WI borrowers), No Collateral Provided",
    subtitle = "Interquartile band with mean and median",
    x = "Approval year",
    y = "Percent",
    caption = "Source: SBA 7(a) FOIA; Field: InitialInterestRate"
  ) +
  theme_im()
p_rate_collateral

