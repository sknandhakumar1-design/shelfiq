from prefect import flow
from prefect.server.schemas.schedules import IntervalSchedule
from datetime import timedelta, datetime
from src.monitoring.retraining_pipeline import retraining_flow

def schedule_retraining():
    print("=" * 60)
    print("ShelfIQ — Retraining Scheduler")
    print("=" * 60)
    
    # Define the schedule (24 hours)
    schedule = IntervalSchedule(interval=timedelta(hours=24))
    
    print(f"Scheduling retraining pipeline to run every 24 hours.")
    print(f"Next run scheduled for: {datetime.now() + timedelta(hours=24)}")
    
    # Create a deployment and serve it
    # Note: .serve() blocks and runs the agent locally
    retraining_flow.serve(
        name="shelfiq-daily-retraining",
        schedule=schedule,
    )

if __name__ == "__main__":
    schedule_retraining()
