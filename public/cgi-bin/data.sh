#!/bin/sh
printf "Content-Type: application/json\r\n\r\n"
ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
python3 - "$ROOT" "library" <<'PY'
import csv,json,os,sys,subprocess,re
root,mode=sys.argv[1],sys.argv[2]
def read(name):
 p=os.path.join(root,"data",name)
 if not os.path.exists(p): return []
 with open(p,newline="",encoding="utf-8") as f: return list(csv.DictReader(f))
d={"title":'Library Book and Circulation Management Dashboard',"mode":mode,"cards":[],"rows":[],"labels":[],"values":[]}
if mode=="attendance":
 rows=read("sample_data.csv"); out=[]; elig=0; sm=0
 for r in rows:
  total=float(r["Total_Classes"] or 0); att=float(r["Attended_Classes"] or 0); pct=att/total*100 if total else 0
  elig+=pct>=75; sm+=pct
  out.append({"Student_ID":r["Student_ID"],"Student_Name":r["Student_Name"],"Attendance_%":round(pct,1),"Status":"Eligible" if pct>=75 else "Below 75%"})
 n=len(out); d.update(cards=[["Total Students",n],["Average Attendance",str(round(sm/n,1) if n else 0)+"%"],["Eligible",elig],["Below 75%",n-elig]],rows=out,labels=["Eligible","Below 75%"],values=[elig,n-elig])
elif mode=="marks":
 rows=read("sample_data.csv"); out=[]; sm=0; passed=0
 for r in rows:
  mx=float(r["Maximum_Marks"] or 100); marks=float(r["Internal_Marks"])+float(r["External_Marks"]); pct=marks/mx*100 if mx else 0
  grade="A" if pct>=80 else "B" if pct>=70 else "C" if pct>=60 else "D" if pct>=50 else "F"; passed+=pct>=40; sm+=pct
  out.append({"Student_ID":r["Student_ID"],"Student_Name":r["Student_Name"],"Subject":r["Subject"],"Total":marks,"Percentage":round(pct,1),"Grade":grade,"Result":"Pass" if pct>=40 else "Fail"})
 n=len(out); d.update(cards=[["Records",n],["Average",str(round(sm/n,1) if n else 0)+"%"],["Pass",passed],["Fail",n-passed]],rows=out,labels=["Pass","Fail"],values=[passed,n-passed],headers=["Student_ID","Student_Name","Subject","Total","Percentage","Grade","Result"])
elif mode=="library":
 books=read("books.csv")
 transactions=read("circulation.csv")
 issued_by_book={}
 for t in transactions:
  status=(t.get("Status") or "").strip().lower()
  if status == "returned":
   continue
  book_id=(t.get("Book_ID") or "").strip()
  if not book_id:
   continue
  issued_by_book[book_id]=issued_by_book.get(book_id,0)+1

 out=[]
 category_counts={}
 for b in books:
  book_id=(b.get("Book_ID") or "").strip()
  category=(b.get("Category") or "").strip()
  total=int(b.get("Total_Copies") or 0)
  issued=issued_by_book.get(book_id,0)
  available=max(total-issued,0)
  out.append({
   "Book_ID": book_id,
   "Title": b.get("Title",""),
   "Author": b.get("Author",""),
   "Category": category,
   "Total_Copies": total,
   "Issued_Copies": issued,
   "Available_Copies": available,
  })
  category_counts[category]=category_counts.get(category,0)+1

 d.update(
  cards=[
   ["Book Titles", len(books)],
   ["Total Copies", sum(int(b.get("Total_Copies") or 0) for b in books)],
   ["Categories", len(category_counts)],
   ["Issued", sum(issued_by_book.values())],
  ],
  rows=out,
  labels=list(category_counts),
  values=list(category_counts.values()),
  headers=["Book_ID","Title","Author","Category","Total_Copies","Issued_Copies","Available_Copies"],
 )
elif mode=="inventory":
 rows=read("sample_data.csv"); out=[]; low=0; qty=0; val=0
 for r in rows:
  stock=int(r["Opening_Stock"])+int(r["Received"])-int(r["Issued"]); amount=stock*float(r["Unit_Price"]); islow=stock<int(r["Reorder_Level"]); low+=islow; qty+=stock; val+=amount
  out.append({"Product_ID":r["Product_ID"],"Product_Name":r["Product_Name"],"Category":r["Category"],"Current_Stock":stock,"Reorder_Level":r["Reorder_Level"],"Inventory_Value":round(amount,2),"Status":"Low" if islow else "OK"})
 d.update(cards=[["Products",len(out)],["Current Stock",qty],["Low Stock",low],["Inventory Value",round(val,2)]],rows=out,labels=[x["Product_Name"] for x in out],values=[x["Current_Stock"] for x in out],headers=["Product_ID","Product_Name","Category","Current_Stock","Reorder_Level","Inventory_Value","Status"])
elif mode=="payroll":
 rows=read("sample_data.csv"); out=[]; gross=net=ded=0; dept={}
 for r in rows:
  b=float(r["Basic_Salary"]); a=float(r["Allowances"]); x=float(r["Deductions"]); g=b+a; n=g-x; gross+=g; net+=n; ded+=x; dept[r["Department"]]=dept.get(r["Department"],0)+n
  out.append({"Employee_ID":r["Employee_ID"],"Employee_Name":r["Employee_Name"],"Department":r["Department"],"Gross_Salary":g,"Deductions":x,"Net_Salary":n})
 d.update(cards=[["Employees",len(out)],["Gross Payroll",gross],["Deductions",ded],["Net Payroll",net]],rows=out,labels=list(dept),values=list(dept.values()),headers=["Employee_ID","Employee_Name","Department","Gross_Salary","Deductions","Net_Salary"])
elif mode=="system":
 def cmd(args):
  try:return subprocess.check_output(args,text=True,stderr=subprocess.DEVNULL).strip()
  except:return "Unavailable"
 mem={}
 try:
  for line in open("/proc/meminfo"):
   k,v=line.split(":",1); mem[k]=int(v.strip().split()[0])
  total=mem.get("MemTotal",0)//1024; avail=mem.get("MemAvailable",0)//1024; used=total-avail; pct=round(used/total*100,1) if total else 0
 except: total=avail=used=pct=0
 uptime=cmd(["uptime","-p"]); load=cmd(["cat","/proc/loadavg"]).split()[:3]; procs=cmd(["sh","-c","ls -d /proc/[0-9]* 2>/dev/null | wc -l"])
 df=cmd(["df","-hP","/"]).splitlines(); disk=" ".join(df[1].split()) if len(df)>1 else "Unavailable"
 d.update(cards=[["RAM Utilization",str(pct)+"%"],["RAM Total",str(total)+" MB"],["Processes",procs],["Uptime",uptime]],rows=[{"Metric":"RAM Used","Value":str(used)+" MB"},{"Metric":"RAM Available","Value":str(avail)+" MB"},{"Metric":"Disk","Value":disk},{"Metric":"Load Average","Value":" ".join(load)}],labels=["RAM Used","RAM Available","Disk","Load Average"],values=[used,avail,0,0])
elif mode=="logs":
 path=os.path.join(root,"data","sample_system.log"); lines=open(path).read().splitlines() if os.path.exists(path) else []; counts={"INFO":0,"WARNING":0,"ERROR":0,"OTHER":0}
 for line in lines:
  found=False
  for k in ("INFO","WARNING","ERROR"):
   if re.search(r"\b"+k+r"\b",line): counts[k]+=1; found=True; break
  if not found: counts["OTHER"]+=1
 d.update(cards=[["Total Events",len(lines)],["Info",counts["INFO"]],["Warnings",counts["WARNING"]],["Errors",counts["ERROR"]]],rows=[{"Log Entry":x} for x in lines[-30:]],labels=list(counts),values=list(counts.values()),headers=["Log Entry"])
print(json.dumps(d))
PY
