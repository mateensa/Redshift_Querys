--This returns max() of date from list of dates passed as varchar format
CREATE OR REPLACE FUNCTION staging.f_get_bom_effective_date_max(textval varchar)
RETURNS varchar
IMMUTABLE AS $$  
import time
list = []  
for tval in textval.split(','): 
	if tval!='':
		list.append(time.strptime(tval, "%d-%b-%y"))
return time.strftime("%d-%b-%y", max(list)).upper()
$$ LANGUAGE plpythonu;

--This returns min() of date from list of dates passed as varchar format
CREATE OR REPLACE FUNCTION staging.f_get_bom_disable_date_min(textval varchar)
RETURNS varchar
IMMUTABLE AS $$  
import time
list = []  
for tval in textval.split(','): 
	if tval!='':
		list.append(time.strptime(tval, "%d-%b-%y"))
	if len(list)>0:
		return_value = time.strftime("%d-%b-%y", min(list)).upper()
	else: 
		return_value = ''
return return_value
$$ LANGUAGE plpythonu;

--This will evaluate math expression
CREATE OR REPLACE FUNCTION staging.f_evaluate_flat_qty(input_string varchar)
RETURNS float
IMMUTABLE AS $$  
return eval(input_string)
$$ LANGUAGE plpythonu;


--Below is bit more complex example (which uses pandas python library class USFederalHolidayCalendar)
-- to calculate days far from given holiday.

create or replace function f_days_from_holiday (year int, month int, day int)
returns int
stable
as $$
  import datetime
  from datetime import date
  import dateutil
  from dateutil.relativedelta import relativedelta

  fdate = date(year, month, day)

  fmt = '%Y-%m-%d'
  s_date = fdate - dateutil.relativedelta.relativedelta(days=7)
  e_date = fdate + relativedelta(months=1)
  start_date = s_date.strftime(fmt)
  end_date = e_date.strftime(fmt)

  """
  Compute a list of holidays over a period (7 days before, 1 month after) for the flight date
  """
  from pandas.tseries.holiday import USFederalHolidayCalendar
  calendar = USFederalHolidayCalendar()
  holidays = calendar.holidays(start_date, end_date)
  days_from_closest_holiday = [(abs(fdate - hdate)).days for hdate in holidays.date.tolist()]
  return min(days_from_closest_holiday)
$$ language plpythonu;



