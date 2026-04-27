import argparse
import json
from predictions.weight_prediction import calculate_weight_prediction
from predictions.financial_forecast import calculate_financial_forecast


def main():
    parser = argparse.ArgumentParser(description="NIX LIFE OS Prediction Models")

    parser.add_argument("--user-id", required=True, help="User UUID")
    parser.add_argument("--type", required=True, choices=[
        "weight",
        "finance",
        "all"
    ])

    parser.add_argument("--days-ahead", type=int, default=30)
    parser.add_argument("--month", required=False, help="Target month YYYY-MM")

    args = parser.parse_args()

    results = {}

    if args.type in ["weight", "all"]:
        results["weight_prediction"] = calculate_weight_prediction(
            user_id=args.user_id,
            days_ahead=args.days_ahead
        )

    if args.type in ["finance", "all"]:
        results["financial_forecast"] = calculate_financial_forecast(
            user_id=args.user_id,
            target_month=args.month
        )

    print(json.dumps(results, indent=4))


if __name__ == "__main__":
    main()