/// Presentation helpers for storefront list/detail chrome.
/// Compares display names only — never fixture IDs or database values.
bool isRedundantMerchantName(String branchName, String merchantName) {
  return branchName.trim().toLowerCase() == merchantName.trim().toLowerCase();
}

const storefrontCardPreviewMaxLines = 2;
