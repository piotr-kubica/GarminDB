# from .garmindb import GarminDb
from garmindb.garmindb import ActivitiesDb, Activities
from garmindb import ConfigManager
from sqlalchemy import Column, String, Float, Integer, DateTime, Time, select
from sqlalchemy.orm import mapper, relationship
import logging
import datetime
import analysis.model
import pandas as pd


class ActivityMapper():

    model = analysis.model.ActivitySummary
    
    def __init__(self):
        db_params = ConfigManager.get_db_params()
        self.db = ActivitiesDb(db_params)
        self.mapper = mapper(analysis.model.ActivitySummary, Activities)

    # working example
    def get_by_sport(self, sport):
        """Return all activities items for a given sport type."""
        with self.db.managed_session() as session:
            return session.query(self.model).filter(self.model.sport == sport).order_by(self.model.start_time).all()

    def to_data_frame(self):
        with self.db.managed_session() as session:
            return pd.read_sql(session.query(self.model).statement, session.bind)
        

