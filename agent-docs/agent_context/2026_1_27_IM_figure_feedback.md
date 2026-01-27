# Figure Feedback from my internal review

For each of the edits below, make sure you reconfigure titles and descriptions accordingly.

## Figure 1

Do not average across years - instead, sum across years to create the figure. Meaning instead taking the mean across years, take the sum.

## Figure 2

See figure 1.

## Figure 3

Similar to before, taking the artifact from figures 1 and 2 to construct this. So we'll take the sum of capital and sum of dealcount seperately across years, and then divide to create deal size.

## Figure 9

Make another change to the legend. The problem is that most of the variation in our data is between 0 and 100, with a few counties (mainly urban ones) above 100 form D filings. So what I'd like you to do is break out the legend such that counties above 100 filings receive a specific color, and we have a color scale for values between 1 and 100.

### 2026-01-27 ad hoc updates

- Switched to binned legend categories (1–25, 26–50, 51–75, 76–100, >100) with a high-contrast color for >100; zero values remain greyed out.
- Legend order should read: 1–25, 26–50, 51–75, 76–100, >100, NA.
- Removed map axes (titles, ticks, labels, grid) from Form D county maps.

## Figure 11

I'd like to change this estimand to be "per capita" over the full period. In other words, sum the numerator across years by group, sum the denominator by year across groups, then take the quotient and adjust so that the figure reads as per 100,000 workers. Change the caption to reflect this - The question we want to answer is "How much Form D capital per worker was raised over 2016–2025?"

## Figure 12

Same idea at a high level. Sum the numerator then the denominator seperately, then divide.

## Figure 18

Same idea at a high level. Sum the numerator then the denominator seperately, then divide.

# Agent clarifications

1. The totals should use the same range (2015-2025) as current
2. Yes, keep the same X axis labels for now. We'll update the spec later if we want to change the X axis label
3. Yes the captions should be the same - percent of the national metric
4. For the ">100" category in figure 9, use a high contrast color. I can finetune manually later if required.
5. Figures 1-3 should have a subtitle that explicitly reads "2015-2025 total"
