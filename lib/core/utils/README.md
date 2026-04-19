# App Utilities Directory (Helpers & Logic)

@Agent_Instruction: This directory contains logic helpers that are used by various features throughout the app. If you need to manipulate strings, numbers, or dates, check if a utility already exists here.

## 🧭 Helper Logic and Patterns

Use the following utilities for common tasks:

### 1. Currency & Spending (`currency_formatter.dart`)
- **Format Currency**: Use `CurrencyFormatter.formatToVnd(double amount)`.
- **Parsing Spending**: Use `SpendingParser.extractAmount(String text)` (Regex logic).

### 2. Regex Helpers (`regex_utils.dart`)
- **Email Validation**: `RegexUtils.isEmailValid(String email)`.
- **Phone Number**: `RegexUtils.isPhoneValid(String phone)`.
- **Spending Extraction**: `RegexUtils.amountPattern` for parsing amounts from captions.

### 3. Date & Time (`date_formatter.dart`)
- **Relative Time**: Use `DateFormatter.toRelativeTime(DateTime date)` for "2 minutes ago".
- **Short Date**: `DateFormatter.toShortDate(DateTime date)`.

### 4. Image Helpers (`image_utils.dart`)
- **Compression**: Use `ImageUtils.compressForUpload(File image)`.
- **Blurring**: `ImageUtils.applyBlurFilter(ui.Image image)`.

## 🛠️ General Guidelines

- **Stateless**: All utility functions must be **static** and **stateless**.
- **Pure Functions**: Ensure that every utility function is a "pure" function (given the same input, it always returns the same output).
- **Unit Testing**: All code in this directory should be highly testable.
