const months=['January','February','March','April','May','June','July','August','September','October','November','December'];

// Parse the precision actually supplied; a bare year is never January 1.
export function archiveDate(value='') {
  const match=/^(\d{4})(?:-(\d{2})(?:-(\d{2}))?)?$/.exec(value);
  if(!match)return {year:null,month:null,day:null};
  const year=match[1],month=match[2]?Number(match[2]):null,day=match[3]?Number(match[3]):null;
  if(month!==null&&(month<1||month>12))return {year,month:null,day:null};
  if(day!==null){
    const date=new Date(Date.UTC(Number(year),month-1,day));
    if(day<1||date.getUTCMonth()!==month-1||date.getUTCDate()!==day)return {year,month,day:null};
  }
  return {year,month,day};
}

export function dateBadge(value) {
  const {year,month,day}=archiveDate(value);
  return {main:day!==null?String(day).padStart(2,'0'):month!==null?'—':year||'—',label:month!==null?months[month-1].toUpperCase():year?'YEAR ONLY':'UNDATED'};
}

export function shortDate(value) {
  const {year,month,day}=archiveDate(value);
  if(!year)return 'Date unknown';
  if(month===null)return `${year} · Exact date unknown`;
  if(day===null)return `${months[month-1]} ${year} · Day unknown`;
  return `${String(month).padStart(2,'0')}/${String(day).padStart(2,'0')}/${year.slice(2)}`;
}

export function monthYear(value) {
  const {year,month}=archiveDate(value);
  return month!==null?`${String(month).padStart(2,'0')}/${year.slice(2)}`:year||'Undated tape';
}
