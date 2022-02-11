
class ActivitySummary():

    # references ActivityData to get all records

    def __init__(self):
        # technical fields
        self.activity_id = None
        self.name = None
        self.description = None
        self.type = None
        self.course_id = None
        self.laps = None
        self.sport = None
        self.sub_sport = None
        # data fields
        self.start_time = None
        self.stop_time = None
        self.elapsed_time = None
        self.moving_time = None
        self.distance = None
        self.cycles = None
        self.avg_hr = None
        self.max_hr = None
        self.calories = None
        self.avg_cadence = None
        self.max_cadence = None
        self.avg_speed = None
        self.max_speed = None
        self.ascent = None
        self.descent = None
        self.max_temperature = None
        self.min_temperature = None
        self.start_lat = None
        self.start_long = None
        self.stop_lat = None
        self.stop_long = None


class ActivityRecord():
    # activity records table
    pass

    # Move to mapper
    # def to_series(self):
    #     pass


class ActivityData():
    # holds list of activity records
    pass

    # Move to mapper
    # def to_data_frame():
    #     pass