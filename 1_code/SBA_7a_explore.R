#///////////////////////////////////////////////////////////////////////////////
#----                              Preamble                                 ----
# File name:  SBA FOIA Analysis: 7(A)
# Previous author:  -
# Current author:   Inder Majumdar
# Creation date:    September 21, 2025
# Last updated: October 7, 2025
# Description: Scratch Data Exploration for 7(A)
#
# Change log:       
#///////////////////////////////////////////////////////////////////////////////

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


##############
# Typecast items
##############

# Approval Date
loans$ApprovalDate <- as.Date(loans$ApprovalDate, format = "%m/%d/%Y")

#Initial Interest Rate
loans$InitialInterestRate = readr::parse_number(loans$InitialInterestRate)
  



# Yearly analysis of SBA Loan Counts: Banks in vs. Out of Wisc  ------------------------------------------------------------------------

loans |>
  filter(BorrState == 'WI') |>
  mutate(ApprovalYear = year(ApprovalDate)) |>
  group_by(ApprovalYear) |>
  summarise(loan_count = n(),
            non_wi_count = sum(BankState != "WI", na.rm = TRUE),
            share_non_wi = non_wi_count/loan_count) -> loanamounts


# Time series: Loan Counts, Total vs. Banks outside of Wisc
ggplot(loanamounts, aes(x = ApprovalYear)) +
  geom_line(aes(y = loan_count)) + 
  geom_line(aes(y = non_wi_count))


# Time series: Percent of loans originating outside of Wisc
ggplot(loanamounts, aes(x = ApprovalYear)) + 
  geom_line(aes(y = share_non_wi))

#rm(loanamounts)

# Yearly analysis of SBA Loan Amounts: Banks in vs. Out of Wisc  ------------------------------------------------------------------------

loans |>
  filter(BorrState == 'WI') |>
  mutate(ApprovalYear = year(ApprovalDate)) |>
  group_by(ApprovalYear) |>
  summarise(loan_total = sum(GrossApproval),
            non_wi_vol = sum(GrossApproval[BankState != "WI"], na.rm = TRUE),
            share_non_wi = non_wi_vol/loan_total) -> loanvolumes

# Time series: Loan Counts, Total vs. Banks outside of Wisc
ggplot(loanvolumes, aes(x = ApprovalYear)) +
  geom_line(aes(y = loan_total)) + 
  geom_line(aes(y = non_wi_vol))


# Time series: Percent of loans originating outside of Wisc
ggplot(loanvolumes, aes(x = ApprovalYear)) + 
  geom_line(aes(y = share_non_wi))

#rm(loanvolumes)


# Yearly analysis of SBA Dollars per loan  ------------------------------------------------------------------------

# All WI Loans

ts <- loans |>
  filter(BorrState == 'WI') |>
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

## Plot (grayscale-friendly via linetype; keep ribbon)
  ggplot(ts, aes(x = ApprovalYear)) +
  geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.2, fill = "grey70") +
  geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
  geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
  geom_point(aes(y = median), size = 1.3) +
  geom_point(aes(y = mean),   size = 1.3) +
  scale_linetype_manual(
    name = "Measure",
    values = c("Median" = "dashed", "Mean" = "solid")
  ) +
  scale_x_continuous(breaks = scales::pretty_breaks()) +
  labs(x = "Year", y = "Approved Loan Amount") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top",
        panel.grid.minor = element_blank())

# WI Loans from Non WI Lenders
  
  
  ts <- loans |>
    filter(BorrState == 'WI', BankState != "WI") |>
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
  
  ## Plot (grayscale-friendly via linetype; keep ribbon)
  ggplot(ts, aes(x = ApprovalYear)) +
    geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.2, fill = "grey70") +
    geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
    geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
    geom_point(aes(y = median), size = 1.3) +
    geom_point(aes(y = mean),   size = 1.3) +
    scale_linetype_manual(
      name = "Measure",
      values = c("Median" = "dashed", "Mean" = "solid")
    ) +
    scale_x_continuous(breaks = scales::pretty_breaks()) +
    labs(x = "Year", y = "Approved Loan Amount") +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top",
          panel.grid.minor = element_blank())
  
  
  # Yearly analysis of interest rate dispersion  ------------------------------------------------------------------------
  
  # All WI Loans
  
  ts <- loans |>
    filter(BorrState == 'WI', !is.na(InitialInterestRate), InitialInterestRate != 0) |>
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
  
  ggplot(ts, aes(x = ApprovalYear)) +
    geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.2, fill = "grey70") +
    geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
    geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
    geom_point(aes(y = median), size = 1.3) +
    geom_point(aes(y = mean),   size = 1.3) +
    scale_linetype_manual(
      name = "Measure",
      values = c("Median" = "dashed", "Mean" = "solid")
    ) +
    scale_x_continuous(breaks = scales::pretty_breaks()) +
    labs(x = "Year", y = "Initial Interest Rates") +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top",
          panel.grid.minor = element_blank())
  
  # All WI Loans from Non WI Lenders
  
  
  ts <- loans |>
    filter(BorrState == 'WI', BankState != "WI", !is.na(InitialInterestRate), InitialInterestRate != 0) |>
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
  
  ggplot(ts, aes(x = ApprovalYear)) +
    geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.2, fill = "grey70") +
    geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
    geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
    geom_point(aes(y = median), size = 1.3) +
    geom_point(aes(y = mean),   size = 1.3) +
    scale_linetype_manual(
      name = "Measure",
      values = c("Median" = "dashed", "Mean" = "solid")
    ) +
    scale_x_continuous(breaks = scales::pretty_breaks()) +
    labs(x = "Year", y = "Initial Interest Rates") +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top",
          panel.grid.minor = element_blank())
  
  # All WI Loans, no collateral
  
  ts <- loans |>
    filter(BorrState == 'WI', CollateralInd == 'N', !is.na(InitialInterestRate), InitialInterestRate != 0) |>
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
  
  ggplot(ts, aes(x = ApprovalYear)) +
    geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.2, fill = "grey70") +
    geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
    geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
    geom_point(aes(y = median), size = 1.3) +
    geom_point(aes(y = mean),   size = 1.3) +
    scale_linetype_manual(
      name = "Measure",
      values = c("Median" = "dashed", "Mean" = "solid")
    ) +
    scale_x_continuous(breaks = scales::pretty_breaks()) +
    labs(x = "Year", y = "Initial Interest Rates") +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top",
          panel.grid.minor = element_blank())
  
  # All WI Loans, collateral posted
  
  ts <- loans |>
    filter(BorrState == 'WI', CollateralInd == 'Y', !is.na(InitialInterestRate), InitialInterestRate != 0) |>
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
  
  ggplot(ts, aes(x = ApprovalYear)) +
    geom_ribbon(aes(ymin = p25, ymax = p75), alpha = 0.2, fill = "grey70") +
    geom_line(aes(y = median, linetype = "Median"), linewidth = 0.9) +
    geom_line(aes(y = mean,   linetype = "Mean"),   linewidth = 0.9) +
    geom_point(aes(y = median), size = 1.3) +
    geom_point(aes(y = mean),   size = 1.3) +
    scale_linetype_manual(
      name = "Measure",
      values = c("Median" = "dashed", "Mean" = "solid")
    ) +
    scale_x_continuous(breaks = scales::pretty_breaks()) +
    labs(x = "Year", y = "Initial Interest Rates") +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top",
          panel.grid.minor = element_blank())
  
