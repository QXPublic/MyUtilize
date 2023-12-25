var Echo1 = JSON.parse($response.body);
Echo1 = {
  "data" : {
    "type" : "adapty_analytics_profile",
    "id" : "98c30805-9b02-4952-8296-42b2213c4bc8",
    "attributes" : {
      "app_id" : "a8c5ac2e-0f65-419a-bdf8-5605def7f71d",
      "total_revenue_usd" : 0,
      "customer_user_id" : "7F4C8B872C7649D88A226C02D88DE4A2",
      "segment_hash" : "2e64d594f57b843f",
      "subscriptions" : {
        "chatai_weekly_3dft_ios_2" : {
          "vendor_transaction_id" : "570001399100831",
          "offer_id" : null,
          "billing_issue_detected_at" : null,
          "is_lifetime" : true,
          "store" : "app_store",
          "vendor_product_id" : "chatai_weekly_3dft_ios_2",
          "vendor_original_transaction_id" : "570001399100831",
          "will_renew" : true,
          "renewed_at" : "2099-12-24T23:32:51.000000+0000",
          "cancellation_reason" : null,
          "active_promotional_offer_id" : null,
          "active_promotional_offer_type" : null,
          "unsubscribed_at" : null,
          "is_active" : true,
          "activated_at" : "2023-12-24T23:32:52.000000+0000",
          "is_refund" : false,
          "is_in_grace_period" : false,
          "active_introductory_offer_type" : "lifetime_trial",
          "expires_at" : "2099-12-27T23:32:51.000000+0000",
          "starts_at" : null,
          "is_sandbox" : false
        }
      },
      "promotional_offer_eligibility" : false,
      "custom_attributes" : {
        "design" : "5",
        "displayReviewText" : "0",
        "obeyPaywallDesignParams" : "0",
        "selectedProduct" : "-1",
        "offerId" : "offer_6",
        "closeSecs" : "0",
        "paywallType" : "session_start_paywall",
        "packagePaymentTrigger" : "0",
        "isFreeOfferPopupDisplayed" : "0",
        "isActive" : "1"
      },
      "profile_id" : "98c30805-9b02-4952-8296-42b2213c4bc8",
      "paid_access_levels" : {
        "premium" : {
          "id" : "premium",
          "is_lifetime" : true,
          "vendor_product_id" : "chatai_weekly_3dft_ios_2",
          "active_promotional_offer_type" : null,
          "cancellation_reason" : null,
          "billing_issue_detected_at" : null,
          "unsubscribed_at" : null,
          "expires_at" : "2099-12-27T23:32:51.000000+0000",
          "will_renew" : true,
          "is_active" : true,
          "offer_id" : null,
          "is_in_grace_period" : false,
          "activated_at" : "2023-12-24T23:32:52.000000+0000",
          "active_promotional_offer_id" : null,
          "renewed_at" : "2099-12-24T23:32:51.000000+0000",
          "is_refund" : false,
          "active_introductory_offer_type" : "lifetime_trial",
          "store" : "app_store",
          "starts_at" : null
        }
      },
      "introductory_offer_eligibility" : false,
      "non_subscriptions" : null
    }
  }
}

$done({body: JSON.stringify(Echo1)});
