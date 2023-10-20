/// 表结构查询工具.Vue版本
/// 
/// puruidong
/// 2021-09-26
Class web.FindTableInfoVue Extends %RegisteredObject
{

/// 返回命名空间列表.
/// 
/// w ##class(web.FindTableInfoVue).getNameSpaceList()
ClassMethod getNameSpaceList(keyword As %String = "") As %String
{
	s returnList=##Class(%DynamicArray).%New()
	s namespace=$ZUTIL(67,6,$j)
	s:keyword'="" keyword=$ZCONVERT(keyword,"U")
	zn "%sys"
	s alnsItem=""
	f  s alnsItem=$o(^CONFIG("Namespaces",alnsItem)) q:alnsItem=""  d
	.q:$e(alnsItem,1)="%"
	.s alnsFilter=$ZCONVERT(alnsItem,"U")
	.q:(keyword'="")&&(alnsFilter'[keyword)
	.s returnObj=##class(%DynamicObject).%New()
	.s returnObj.label=alnsItem
	.s returnObj.value=alnsItem
	.d returnList.%Push(returnObj)
	zn namespace
	q returnList.%ToJSON()
}

/// 根据命名空间返回包列表
/// 
/// w ##class(web.FindTableInfoVue).getPackageList("DHC-APP","User")
ClassMethod getPackageList(nameSpace As %String = "", keyword As %String = "") As %String
{
	s returnList=##Class(%DynamicArray).%New()
	q:(nameSpace="")!(keyword="") returnList.%ToJSON()
	s currentNamespace=$ZUTIL(67,6,$j)
	s:keyword'="" keyword=$ZCONVERT(keyword,"U")
	zn nameSpace
	s obj=##class(%PackageDefinition).%New("WEB")
	s PackageList= obj.GetPackageList()
	s returnTmp(1)=""
	f i=1:1:PackageList.Count() d
	.s package=PackageList.GetAt(i)
	.q:package["%"
	.s sc=$System.OBJ.GetPackageList(.PLIST,package)
	.q:'sc
	.s packageName11223333=$o(PLIST(""))
	.q:packageName11223333="" 
	.s packageFirst=$p(package,".",1)
	.q:packageFirst="ENSLIB"
	.q:packageFirst="SYSTEM"
	.q:packageFirst="CSP"
	.s packageName=$PIECE(packageName11223333,".",1,$l(packageName11223333,".")-1)
	.q:packageName=""
	.q:$d(returnTmp(packageName))
	.s packageNameFilter=$ZCONVERT(packageName,"U")
	.q:(keyword'="")&&(packageNameFilter'[keyword)
	.s returnTmp(packageName)="1"
	.s returnObj=##class(%DynamicObject).%New()
	.s returnObj.label=packageName
	.s returnObj.value=packageName
	.d returnList.%Push(returnObj)
	
	zn currentNamespace
	q returnList.%ToJSON()
}

/// 根据命名空间,包名,获取前十个类(默认前十).
/// 
/// w ##class(web.FindTableInfoVue).getClassNameList("DHC-APP","User","PA")
ClassMethod getClassNameList(nameSpace As %String = "", package As %String = "", keyword As %String = "", count As %String = "10")
{
	s returnList=##Class(%DynamicArray).%New()
	q:(nameSpace="")!(package="")!(keyword="") returnList.%ToJSON()
	s:keyword'="" keyword=$ZCONVERT(keyword,"U")
		
	set rs=##class(%ResultSet).%New("web.FindTableInfoVue:SelectClass")
	set sc=rs.Execute(nameSpace,package,keyword,count)  If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc) Quit
	while rs.%Next() { 
		s returnObj=##class(%DynamicObject).%New()
		s returnObj.label=rs.GetData(1)
		s returnObj.value=rs.GetData(1)
		d returnList.%Push(returnObj)			
	}
	
	q returnList.%ToJSON()
}

/// 查询包下面的所有类(默认前十个)
/// 
Query SelectClass(nameSpace As %String, packageName As %String, preClassName As %String, count As %String = "") As %Query(ROWSPEC = "className:%String:类名")
{
}

ClassMethod SelectClassExecute(ByRef qHandle As %Binary, nameSpace As %String, packageName As %String, preClassName As %String, count As %String = "") As %Status
{
	Set repid=$I(^CacheTemp)
    If $g(ind)="" Set ind=1	
    k PLIST
	I (preClassName="")!(nameSpace="")!(preClassName="")  Set qHandle=$lb(0,repid,0) Quit $$$OK
	s currentNamespace=$ZUTIL(67,6,$j)
	s:count="" count=10
	zn nameSpace
	s sog=$System.OBJ.GetPackageList(.PLIST,packageName,"")
	Do:('sog) $system.Status.DisplayError(sog)
	
	s len = $l(preClassName)
	s name="",currentClassCnt=0
	f  s name=$o(PLIST(name)) q:(name="")||(currentClassCnt>(+count))  d
	.s allName=$p(name,packageName_".",2)
	.s preName=$e(allName,1,len)
	.q:($ZCVT(preName,"U")'=$ZCVT(preClassName,"U"))  
	.s outClassName=allName
	.s currentClassCnt=currentClassCnt+1
	.do OutputRowClass
	
	k PLIST
	zn currentNamespace
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRowClass
	set Data=$lb(outClassName)
 	Set ^CacheTemp(repid,ind)=Data
 	Set ind=ind+1
}

ClassMethod SelectClassClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = SelectClassExecute ]
{
	Set repid=$LIST(qHandle,2)
 	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod SelectClassFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = SelectClassExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
 	Set ind=$LIST(qHandle,3)
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				// if there are no more rows, finish fetching
 		Set AtEnd=1
	 	Set Row=""
 	}
 	Else      {				// fetch row
 		Set Row=^CacheTemp(repid,ind)
 	}
 	// Save QHandle
 	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 获取该类的父表
/// w ##class(web.FindTableInfoVue).getParentTable("DHC-APP","User","OEOrdItem")
ClassMethod getParentTable(nameSpace As %String, packageName As %String, className As %String) As %String
{
	q:((nameSpace="")||(packageName="")||(className="")) ""
	s $zt="Error"
	s currentNamespace=$ZUTIL(67,6,$j)
	zn nameSpace
	set parentClass=""
	Set rs = ##class(%ResultSet).%New("%Dictionary.PropertyDefinition:Summary")
	do rs.Execute(className)
	While(rs.Next()) {
		set propertyName=rs.Data("Name")
		set propId=packageName_"."_className_"||"_propertyName
		set propObj=##class(%Dictionary.PropertyDefinition).%OpenId(propId,0)
   	  	quit:propObj=""
   	  	if propObj.Cardinality="parent" d
   	  	.s parentClass=$p(propObj.Type,".",$l(propObj.Type,"."))
   	}
   	zn currentNamespace
   	q $g(parentClass)
Error
	zn currentns
	q ""
}

/// 子表列表.
///  
/// w ##class(web.FindTableInfoVue).getChildTableList("DHC-APP","User","OEOrder")
ClassMethod getChildTableList(nameSpace As %String, packageName As %String, className As %String) As %String
{
	q:((nameSpace="")||(packageName="")||(className="")) ""
	s $zt="Err"
	s returnList=##Class(%DynamicArray).%New()
	s currentNamespace=$ZUTIL(67,6,$j)
	zn nameSpace
	Set rs = ##class(%ResultSet).%New("%Dictionary.PropertyDefinition:Summary")
	do rs.Execute(className)
	While(rs.Next()) {
		set propertyName=rs.Data("Name")
		set propId=packageName_"."_className_"||"_propertyName
		set propObj=##class(%Dictionary.PropertyDefinition).%OpenId(propId,0)
   	  	quit:propObj=""
   	  	if propObj.Cardinality="children" d
   	  	.set childName=$p(propObj.Type,".",$l(propObj.Type,"."))
   	  	.s returnObj=##class(%DynamicObject).%New()
		.s returnObj.label=childName
		.s returnObj.value=childName
		.d returnList.%Push(returnObj)		
   	}
   	
   zn currentNamespace
   q returnList.%ToJSON()
Err
	zn currentNamespace
   	q returnList.%ToJSON()
}

/// input: 命名空间,包名,类名
/// desc:  查询表的结构
/// 
/// d ##class(%ResultSet).RunQuery("web.FindTableInfoVue","getTableMaster","DHC-APP","User","PAAdm")
Query getTableMaster(nameSpace As %String, packageName As %String, className As %String) As %Query(ROWSPEC = "type:%String:索引类型,indexName:%String:索引名,indexMasterData:%String:索引结构")
{
}

ClassMethod getTableMasterExecute(ByRef qHandle As %Binary, nameSpace As %String, packageName As %String, className As %String) As %Status
{
	Set repid=$I(^CacheTemp)
    If $g(ind)="" Set ind=1
    s currentNamespace=$ZUTIL(67,6,$j)
	i nameSpace'=""  d
	.zn nameSpace
	s sc=$System.OBJ.GetPackageList(.PLIST,packageName,"")
	d:('sc) $system.Status.DisplayError(sc)
	s find=0
	s name=""
	f  s name=$o(PLIST(name)) q:(name="")||(find=1)  d
	.s clsName=$e(name,$l(packageName)+2,$l(name))
	.q:clsName'=className
	.s find=1
	.s packageName=$e(name,1,$l(packageName))
	i find=0 Set qHandle=$lb(0,repid,0) zn currentNamespace Quit $$$OK
	set classAllName=packageName_"."_className
	set dcd = ##class(%Dictionary.ClassDefinition).%OpenId(classAllName)
	if (dcd="")  Set qHandle=$lb(0,repid,0) zn currentns Quit $$$OK
	set dsd=dcd.Storages
	set dsdCount=dsd.Count()
	s storageType="%CacheSQLStorage"
	for j=1:1:dsdCount 	d
	.s storage = dsd.GetAt(j)
	.s storageType = storage.Type	; %Dictionary.CacheClassname
	.i storageType = "%Library.CacheStorage" d
	..s storageIndexMasterData=storage.IndexLocation
	..s storageDatas = storage.Data		;%Dictionary.StorageDataDefinition
	..s storageDatasCount = storageDatas.Count()
	..f y=1:1:storageDatasCount d
	...s storageData=storageDatas.GetAt(y)
	...s storageDataValue=storageData.Values	;%Dictionary.StorageDataValueDefinition
	...s storageDataValueCount=storageDataValue.Count()
	...s type = "Data"	
	...s indexName=storageData.Name
	...s storageStructure=storageData.Structure
	...i storageStructure="node"  s indexMasterData=storage.DataLocation_"(ID,0)="_storageData.Attribute
	...e  d
	....s indexSub=""
	....for x=1:1:storageDataValueCount d
	.....i indexSub'="" s indexSub=indexSub_","_storageDataValue.GetAt(x).Value
	.....e  s indexSub=storageDataValue.GetAt(x).Value
	....s indexMasterData=storage.DataLocation_"(ID)=$LB("_indexSub_")"
	...d OutputRowMaster1122
	.e  d 
	..s sqlMapsID = storage.SQLMaps
	..s sqlMapsCount=sqlMapsID.Count()
	..for i=1:1:sqlMapsCount d
	...set sqlMapID=sqlMapsID.GetAt(i)
	...set type=sqlMapID.Type
	...set indexName=sqlMapID.Name
	...zn:nameSpace'="" nameSpace
	...set indexSub=..getIndexSubStr(sqlMapID.Subscripts)
	...set indexMasterData=sqlMapID.Global_indexSub
	...d OutputRowMaster1122
	zn currentNamespace
	i storageType '= "%Library.CacheStorage" Set qHandle=$lb(0,repid,0) Quit $$$OK
	s indexDefinitions = dcd.Indices
	s indicesCount = indexDefinitions.Count()
	f i=1:1:indicesCount d
	.s indexDefinition = indexDefinitions.GetAt(i)
	.s type="Index"
	.s indexName=indexDefinition.Name
	.s indexMasterData = storageIndexMasterData_"("""_indexName_""","_indexDefinition.Properties_",ID)"
	.d OutputRowMaster1122
	zn currentns
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRowMaster1122
	set Data=$lb($g(type),$g(indexName),$g(indexMasterData))
 	Set ^CacheTemp(repid,ind)=Data
 	Set ind=ind+1
}

ClassMethod getTableMasterClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = getTableMasterExecute ]
{
	Set repid=$LIST(qHandle,2)
 	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod getTableMasterFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = getTableMasterExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
 	Set ind=$LIST(qHandle,3)
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				// if there are no more rows, finish fetching
 		Set AtEnd=1
	 	Set Row=""
 	}
 	Else      {				// fetch row
 		Set Row=^CacheTemp(repid,ind)
 	}
 	// Save QHandle
 	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 描述:    得到主索引或索引的subString
/// 返回:    subString:   (0,"BillDate",{PBDO_BillDate},{PBDO_RowId})
/// 入参:    subScripts
/// [Previously private]
ClassMethod getIndexSubStr(subScripts)
{
	s subCnt=subScripts.Count(),subString="("
	for k=1:1:subCnt {
				set subScript=subScripts.GetAt(k)	
				set expr=subScript.Expression
				set subString=subString_""_expr_","
	}
	set $e(subString,$l(subString))=""   //去掉最后的逗号
	q subString_")"
}

/// 查询表结构JSON信息.
/// w ##class(web.FindTableInfoVue).getTableMasterJSON("DHC-APP","User","PAAdm")
/// 
ClassMethod getTableMasterJSON(nameSpace As %String, packageName As %String, className As %String)
{
	s result={}
    s result.Total=0
    s result.Data=[]
    
	q:(nameSpace="")!(packageName="")!(className="") result.%ToJSON()
	set rs=##class(%ResultSet).%New("web.FindTableInfoVue:getTableMaster")
	set sc=rs.Execute(nameSpace,packageName,className)  If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc) Quit
	
	s dataMaster=""
	s returnList=##Class(%DynamicArray).%New()
	while rs.%Next() { 
		s returnObj=##class(%DynamicObject).%New()
		s returnObj.indexType=rs.GetData(1)
		s returnObj.indexName=rs.GetData(2)
		s returnObj.indexMasterData=rs.GetData(3)
		if (returnObj.indexType="data"){
			s dataMaster=returnObj
		}
		continue:returnObj.indexType="data"
		d returnList.%Push(returnObj)			
	}
	
	/// 数据为空则返回空(不添加搜索行).
	q:returnList.%Size()=0 result.%ToJSON()
	
	s returnListNew=##Class(%DynamicArray).%New()
	/// 首行留给搜索.
	s returnObj=##class(%DynamicObject).%New()
	s returnObj.indexType=""
	s returnObj.indexName=""
	s returnObj.indexMasterData=""
	d returnListNew.%Push(returnObj)
	
	d:dataMaster'="" returnListNew.%Push(dataMaster)
	f index=0:1:returnList.%Size() d
	.s item=returnList.%Get(index)
	.q:item=""
	.d returnListNew.%Push(item)
	
	s total=returnListNew.%Size()
	s returnNewObj={}
	s returnNewObj.Data=returnListNew
	s returnNewObj.Total=total
	q returnNewObj.%ToJSON()
}

/// 获取属性列表
/// 
/// d ##class(%ResultSet).RunQuery("web.Util.DHCJFClassGlobal","getPropertyList","DHC-APP","User","PAAdm","")
Query getPropertyList(nameSpace As %String, packageName As %String, className As %String, masterIndexName As %String, sortKey As %String = "", SearchKeywordStr As %String = "") As %Query(ROWSPEC = "propertyName:%String,propertyNode:%String,propertyDeli:%String,propertyPiece:%String,propertyType:%String,propertyField:%String,propertyColumn:%String,Description:%String")
{
}

ClassMethod getPropertyListExecute(ByRef qHandle As %Binary, nameSpace As %String, packageName As %String, className As %String, masterIndexName As %String, sortKey As %String = "", SearchKeywordStr As %String = "") As %Status
{
	Set repid=$I(^CacheTemp)
    If $g(ind)="" Set ind=1	
	i (packageName="")||(className="") Set qHandle=$lb(0,repid,0) Quit $$$OK
	s currentNamespace=$ZUTIL(67,6,$j)
	k PLIST
	zn:nameSpace'="" nameSpace
	s sc=$System.OBJ.GetPackageList(.PLIST,packageName,"")
	d:('sc) $system.Status.DisplayError(sc)
	b ; 012
	s (propertyNameSearch,propertyNodeSearch,propertyDeliSearch,propertyPieceSearch,propertyTypeSearch,propertyFieldSearch,DescriptionSearch,propertyColumnSearch)=""
	s SearchKeywordObj=##class(%DynamicObject).%New()
	b ; 011
	try {
        set:SearchKeywordStr'="" SearchKeywordObj = ##class(%DynamicObject).%FromJSON(SearchKeywordStr)
        s propertyNameSearch=SearchKeywordObj.%Get("propertyName")
		s propertyNodeSearch=SearchKeywordObj.%Get("propertyNode")
		s propertyDeliSearch=SearchKeywordObj.%Get("propertyDeli")
		s propertyPieceSearch=SearchKeywordObj.%Get("propertyPiece")
		s propertyTypeSearch=SearchKeywordObj.%Get("propertyType")
		s propertyFieldSearch=SearchKeywordObj.%Get("propertyField")
		s DescriptionSearch=SearchKeywordObj.%Get("Description")
		s propertyColumnSearch=SearchKeywordObj.%Get("propertyColumn")
		
		s:propertyNameSearch'="" propertyNameSearch=$ZCONVERT(propertyNameSearch,"U")
		s:propertyNodeSearch'="" propertyNodeSearch=$ZCONVERT(propertyNodeSearch,"U")
		s:propertyDeliSearch'="" propertyDeliSearch=$ZCONVERT(propertyDeliSearch,"U")
		s:propertyPieceSearch'="" propertyPieceSearch=$ZCONVERT(propertyPieceSearch,"U")
		s:propertyTypeSearch'="" propertyTypeSearch=$ZCONVERT(propertyTypeSearch,"U")
		s:propertyFieldSearch'="" propertyFieldSearch=$ZCONVERT(propertyFieldSearch,"U")
		s:DescriptionSearch'="" DescriptionSearch=$ZCONVERT(DescriptionSearch,"U")
		s:propertyColumnSearch'="" propertyColumnSearch=$ZCONVERT(propertyColumnSearch,"U")
		
    } catch ex {
        set SearchKeywordObj = ""
        ;w ex.DisplayString(),!
        b ; err.
    }
	
	s find=0
	s name=""
	f  s name=$o(PLIST(name)) q:(name="")||(find=1)  d
	.s clsName=$e(name,$l(packageName)+2,$l(name))
	.q:clsName'=className
	.s find=1
	.s packageName=$e(name,1,$l(packageName))
	s classAllName=packageName_"."_className
	s:sortKey="" sortKey="propertyName"
	Set rsltSt = ##class(%ResultSet).%New("%Dictionary.PropertyDefinition:Summary")
	do rsltSt.Execute(classAllName)
	Set clsdefinition = ##class(%Dictionary.ClassDefinition).%OpenId(classAllName)
	set StorageStrategy=clsdefinition.StorageStrategy
	While(rsltSt.Next()) {
		s (propertyName,propertyNode,propertyDeli,propertyPiece,propertyType,propertyField,propertyColumn)=""
		set propertyName=rsltSt.Data("Name")
		continue:(propertyNameSearch'="")&&($ZCONVERT(propertyName,"U")'[propertyNameSearch)
		set propertyId=classAllName_"||"_propertyName
		set propObj=##class(%Dictionary.PropertyDefinition).%OpenId(propertyId,0)
		set propertyType=propObj.Type
		continue:(propertyTypeSearch'="")&&($ZCONVERT(propertyType,"U")'[propertyTypeSearch)
		if ($l(propertyType,".")=1)&&($l(propertyType,"%")=1) s propertyType="User."_propertyType
		set propertyField=propObj.SqlFieldName
		set propertyColumn=propObj.SqlColumnNumber
		s Description=propObj.Description
		
		continue:(propertyColumnSearch'="")&&($ZCONVERT(propertyColumn,"U")'[propertyColumnSearch)
		continue:(DescriptionSearch'="")&&($ZCONVERT(Description,"U")'[DescriptionSearch)
		continue:(propertyFieldSearch'="")&&($ZCONVERT(propertyField,"U")'[propertyFieldSearch)
		
		if (masterIndexName="") {
			s masterIndexName=..getMasterIndexNameNamespace(nameSpace,packageName,className)
		}
		s ssmddID=classAllName_"||"_StorageStrategy_"||"_masterIndexName_"||"_propertyField
		set ssmdd=##class(%Dictionary.StorageSQLMapDataDefinition).%OpenId(ssmddID,0)
		if (ssmdd'="") {
			set propertyNode=ssmdd.Node
			set propertyDeli=ssmdd.Delimiter
			set propertyPiece=ssmdd.Piece
		}
		continue:(propertyNodeSearch'="")&&($ZCONVERT(propertyNode,"U")'[propertyNodeSearch)
		continue:(propertyDeliSearch'="")&&($ZCONVERT(propertyDeli,"U")'[propertyDeliSearch)
		continue:(propertyPieceSearch'="")&&($ZCONVERT(propertyPiece,"U")'[propertyPieceSearch)

		i sortKey="propertyName" {
			s propertyNameSort=$ZCONVERT(propertyName,"U")
			s PropertyListSortArr(propertyNameSort)=$lb(propertyName,propertyNode,propertyDeli,propertyPiece,propertyType,propertyField,propertyColumn,Description)
		}
		i sortKey="propertyNode"{
			s propertyNodeSort=$ZCONVERT(propertyNode,"U")
			s:propertyNode="" propertyNodeSort="9999999"_$RANDOM(10000)
			s PropertyListSortArr(propertyNodeSort)=$lb(propertyName,propertyNode,propertyDeli,propertyPiece,propertyType,propertyField,propertyColumn,Description)
		}
		i sortKey="propertyPiece"{
			s propertyPieceSort=$ZCONVERT(propertyPiece,"U")
			s:propertyPiece="" propertyPieceSort="9999999"_$RANDOM(10000)
			s PropertyListSortArr(propertyPieceSort)=$lb(propertyName,propertyNode,propertyDeli,propertyPiece,propertyType,propertyField,propertyColumn,Description)
		}
		i sortKey="propertyField"{
			
			s propertyFieldSort=$ZCONVERT(propertyField,"U")
			s:propertyField="" propertyFieldSort="9999999"_$RANDOM(10000)
			s PropertyListSortArr(propertyFieldSort)=$lb(propertyName,propertyNode,propertyDeli,propertyPiece,propertyType,propertyField,propertyColumn,Description)
		}
		i sortKey="propertyColumn"{
			s propertyColumnSort=$ZCONVERT(propertyColumn,"U")
			s:propertyColumn="" propertyColumnSort="9999999"_$RANDOM(10000)
			s PropertyListSortArr(propertyColumnSort)=$lb(propertyName,propertyNode,propertyDeli,propertyPiece,propertyType,propertyField,propertyColumn,Description)
		}
	}
	s item="" f  s item=$O(PropertyListSortArr(item)) q:item=""  d
	.s Data=PropertyListSortArr(item)
	.d OutputRowProperty1122
	k PLIST
	zn currentNamespace
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRowProperty1122
	; set Data=$lb(propertyName,propertyNode,propertyDeli,propertyPiece,propertyType,propertyField,propertyColumn,Description)
 	Set ^CacheTemp(repid,ind)=Data
 	Set ind=ind+1
}

ClassMethod getPropertyListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = getPropertyListExecute ]
{
	Set repid=$LIST(qHandle,2)
 	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod getPropertyListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = getPropertyListExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
 	Set ind=$LIST(qHandle,3)
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				// if there are no more rows, finish fetching
 		Set AtEnd=1
	 	Set Row=""
 	}
 	Else      {				// fetch row
 		Set Row=^CacheTemp(repid,ind)
 	}
 	// Save QHandle
 	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod getMasterIndexNameNamespace(nameSpace As %String, packageName As %String, className As %String)
{
	s currentns=$ZUTIL(67,6,$j)
	zn nameSpace
	set classAllName=packageName_"."_className
	set masterIndexName=""
	set dcd = ##class(%Dictionary.ClassDefinition).%OpenId(classAllName,0)
	set dsd=dcd.Storages
	set dsdCount=dsd.Count()
	for j=1:1:dsdCount {
		s sqlMapsID=dsd.GetAt(j).SQLMaps
		s sqlMapsCount=sqlMapsID.Count()
		for i=1:1:sqlMapsCount {
			set sqlMapID=sqlMapsID.GetAt(i)
			set type=sqlMapID.Type
			set indexName=sqlMapID.Name
			i type="data" s masterIndexName=indexName
		}	
	}
	zn currentns
	q masterIndexName
}

/// 查询表属性JSON信息.
/// w ##class(web.FindTableInfoVue).getPropertyListJSON(20,1,"DHC-APP","User","PAAdm","","","")
/// 
ClassMethod getPropertyListJSON(rows As %String, page As %String, nameSpace As %String, packageName As %String, className As %String, masterIndexName As %String = "", sortKey As %String = "", SearchKeywordJSON As %String = "")
{
	s result={}
    s result.Total=0
    s result.Data=[]
	q:(nameSpace="")!(packageName="")!(className="") result.%ToJSON()
	s:page="" page=1
    s:rows="" rows=20
    
	set rs=##class(%ResultSet).%New("web.FindTableInfoVue:getPropertyList")
	set sc=rs.Execute(nameSpace,packageName,className,masterIndexName,sortKey,SearchKeywordJSON)  If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc) Quit
	s tmpPatIndex=0
	while rs.%Next() {
		s propertyName=rs.Get("propertyName")
		s propertyNode=rs.Get("propertyNode")
		s propertyDeli=rs.Get("propertyDeli")
		s propertyPiece=rs.Get("propertyPiece")
		s propertyType=rs.Get("propertyType")
		s propertyField=rs.Get("propertyField")
		s propertyColumn=rs.Get("propertyColumn")
		s Description=rs.Get("Description")
		s tmpPatIndex=tmpPatIndex+1 // 输出总数量
        set Data=$lb(propertyName,propertyNode,propertyDeli,propertyPiece,propertyType,propertyField,propertyColumn,Description)
        set DataResult(tmpPatIndex)=Data			
	}
	s data=##Class(%DynamicArray).%New()
	/// 首行的位置留给搜索框.
    s ObjOutData=##class(%DynamicObject).%New() 
    d ObjOutData.%Set("propertyName","")
    d ObjOutData.%Set("propertyNode","")
    d ObjOutData.%Set("propertyDeli","")
    d ObjOutData.%Set("propertyPiece","")
    d ObjOutData.%Set("propertyType","")
    d ObjOutData.%Set("propertyField","")
    d ObjOutData.%Set("propertyColumn","")
    d ObjOutData.%Set("Description","")
    d data.%Push(ObjOutData)
    s result.Total=1
    s result.Data=data
	
	/// 数据为空则返回空.
	q:tmpPatIndex=0 result.%ToJSON()
	b ; 66660
	s TotalNum=tmpPatIndex
    s startRow=(page-1)*rows+1
    s maxRow=startRow-1+rows
    i maxRow>TotalNum d
    .s maxRow=TotalNum
    
    i maxRow<=TotalNum d
    .f i=startRow:1:maxRow d
    ..s ItmGrpInfo=DataResult(i)
    ..q:ItmGrpInfo=""
    ..s ObjOutData=##class(%DynamicObject).%New() 
    ..s propertyName=$lg(ItmGrpInfo,1)
    ..s propertyNode=$lg(ItmGrpInfo,2)
    ..s propertyDeli=$lg(ItmGrpInfo,3)
    ..s propertyPiece=$lg(ItmGrpInfo,4)
    ..s propertyType=$lg(ItmGrpInfo,5)
    ..s propertyField=$lg(ItmGrpInfo,6)
    ..s propertyColumn=$lg(ItmGrpInfo,7)
    ..s Description=$lg(ItmGrpInfo,8)
    ..d ObjOutData.%Set("propertyName",propertyName)
    ..d ObjOutData.%Set("propertyNode",propertyNode)
    ..d ObjOutData.%Set("propertyDeli",propertyDeli)
    ..d ObjOutData.%Set("propertyPiece",propertyPiece)
    ..d ObjOutData.%Set("propertyType",propertyType)
    ..d ObjOutData.%Set("propertyField",propertyField)
    ..d ObjOutData.%Set("propertyColumn",propertyColumn)
    ..d ObjOutData.%Set("Description",Description)
    ..d data.%Push(ObjOutData)
    
    s result.Total=TotalNum
    s result.Data=data
    q result.%ToJSON()
}

/// 获取类的表名.
/// 
ClassMethod getClassSQLTableName(nameSpace As %String, packageName As %String, className As %String)
{
	s currentns=$ZUTIL(67,6,$j)
	zn nameSpace
	set classAllName=packageName_"."_className
	set masterIndexName=""
	set dcd = ##class(%Dictionary.ClassDefinition).%OpenId(classAllName,0)
	set tableName=dcd.SqlTableName
	zn currentns
	q tableName
}

/// ///////////////////////////////////// ----- 下面Global数据查询.
/// 
/// 
/// 
/// 
/// 
/// 根据Global名称,查询表信息.
/// 
/// 没有索引,只能遍历所用表,除非自己建表表,但没有实时性
/// 
/// d ##class(%ResultSet).RunQuery("web.FindTableInfoVue","getClassByGlobal","User","^PAAdm")
Query getClassByGlobal(PackageName As %String, GlobalName As %String, SearchKeywordJSON As %String = "") As %Query(ROWSPEC = "ClassAllName:%String,TableName:%String,SubScriptString:%String,IndexType:%String")
{
}

ClassMethod getClassByGlobalExecute(ByRef qHandle As %Binary, PackageName, GlobalName As %String, SearchKeywordJSON As %String = "") As %Status
{
	Set repid=$I(^CacheTemp)
    If $g(ind)="" Set ind=1	
    i GlobalName="" Set qHandle=$lb(0,repid,0) Quit $$$OK
    s GlobalName=$ZCVT(GlobalName,"U")
    if $l(GlobalName,"^")=1 set GlobalName="^"_GlobalName
    s GlobalNameLen=$l(GlobalName)
    s PackageNameLen = $l(PackageName)
    
    s (classNameSearch,tableNameSearch,subScriptSearch,indexTypeSearch)=""
	s SearchKeywordObj=##class(%DynamicObject).%New()
	b ; 011
	try {
        set:SearchKeywordJSON'="" SearchKeywordObj = ##class(%DynamicObject).%FromJSON(SearchKeywordJSON)
        s classNameSearch=SearchKeywordObj.%Get("className")
		s tableNameSearch=SearchKeywordObj.%Get("tableName")
		s subScriptSearch=SearchKeywordObj.%Get("subScript")
		s indexTypeSearch=SearchKeywordObj.%Get("indexType")
    } catch ex {
        set SearchKeywordObj = ""
        ;w ex.DisplayString(),!
        b ; err.
    }
    
	;------ %Dictionary.StorageSQLMapDefinition.Master ---
	s classAllName="" f  s classAllName = $o(^oddDEF(classAllName)) q:classAllName=""  d
	.q:(classNameSearch'="")&&($ZCONVERT(classAllName,"U")'[$ZCONVERT(classNameSearch,"U"))
	.s storageName="" f  s storageName = $o(^oddDEF(classAllName,"s",storageName)) q:storageName=""  d
	..;Default
	..i ($d(^oddDEF(classAllName,"s","Default"))=11) && ($d(^oddDEF(classAllName,"s","Default",24))=1) d
	...s TableName = classAllName
	...q:(tableNameSearch'="")&&(TableName'[tableNameSearch)
	...s global = ^oddDEF(classAllName,"s","Default",24)
	...s SubScriptString = ^oddDEF(classAllName,"s","Default",24)
	...q:(subScriptSearch'="")&&($ZCONVERT(SubScriptString,"U")'[$ZCONVERT(subScriptSearch,"U"))
	...q:$ZCVT($e(global,1,GlobalNameLen),"U")'=GlobalName
	...s IndexType = "Default data"
	...q:(indexTypeSearch'="")&&(IndexType'[indexTypeSearch)
	...do OutputRowClassByGlobal
	..q:$d(^oddDEF(classAllName,"s","Default"))
	..;SQLStore
	..s sqlmapName="" f  s sqlmapName = $o(^oddDEF(classAllName,"s",storageName,"S",sqlmapName)) q:sqlmapName=""  d
	...s global=$g(^oddDEF(classAllName,"s",storageName,"S",sqlmapName,24),$g(^%qCacheObjectKey(1,"S",24)))
	...q:global=""
	...q:$ZCVT($e(global,1,GlobalNameLen),"U")'=GlobalName
	...s TableName=$s($d(^oddDEF(classAllName,58))#2:^(58),1:$g(^%qCacheObjectKey(1,"c",58)))
	...q:(tableNameSearch'="")&&($ZCONVERT(TableName,"U")'[$ZCONVERT(tableNameSearch,"U"))
	...s IndexType=$g(^oddDEF(classAllName,"s",storageName,"S",sqlmapName,5),$g(^%qCacheObjectKey(1,"S",5)))
	...q:(indexTypeSearch'="")&&($ZCONVERT(IndexType,"U")'[$ZCONVERT(indexTypeSearch,"U"))
	...s SubScriptString=""
	...s subScriptName="" f  s subScriptName=$o(^oddDEF(classAllName,"s",storageName,"S",sqlmapName,"B",subScriptName)) q:subScriptName=""  d
	....s Expression=$g(^oddDEF(classAllName,"s",storageName,"S",sqlmapName,"B",subScriptName,24),$g(^%qCacheObjectKey(1,"B",24)))
	....i SubScriptString="" s SubScriptString=Expression
	....e  s SubScriptString=SubScriptString_","_Expression
	...s:SubScriptString'="" SubScriptString=global_"("_SubScriptString_")"
	...q:(subScriptSearch'="")&&($ZCONVERT(SubScriptString,"U")'[$ZCONVERT(subScriptSearch,"U"))
	...do OutputRowClassByGlobal
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRowClassByGlobal
	set Data=$lb(classAllName,TableName,SubScriptString,IndexType)
 	Set ^CacheTemp(repid,ind)=Data
 	Set ind=ind+1
}

ClassMethod getClassByGlobalClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = getClassByGlobalExecute ]
{
	Set repid=$LIST(qHandle,2)
 	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod getClassByGlobalFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = getClassByGlobalExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
 	Set ind=$LIST(qHandle,3)
 	Set ind=$o(^CacheTemp(repid,ind))
 	If ind="" {				// if there are no more rows, finish fetching
 		Set AtEnd=1
	 	Set Row=""
 	}
 	Else      {				// fetch row
 		Set Row=^CacheTemp(repid,ind)
 	}
 	// Save QHandle
 	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 查询Global表JSON信息.
/// w ##class(web.FindTableInfoVue).getGlobalTableListJSON(20,1,"User","PAAdm","")
/// 
ClassMethod getGlobalTableListJSON(rows As %String, page As %String, packageName As %String, globalName As %String, SearchKeywordJSON As %String = "")
{
	s result={}
    s result.Total=0
    s result.Data=[]
    s:page="" page=1
    s:rows="" rows=20
    q:(packageName="")!(globalName="") result.%ToJSON()
	
	set rs=##class(%ResultSet).%New("web.FindTableInfoVue:getClassByGlobal")
	set sc=rs.Execute(packageName,globalName,SearchKeywordJSON)  If $$$ISERR(sc) Do DisplayError^%apiOBJ(sc) Quit
	s (tmpPatIndex,tmpDataIndex,tmpIndexS)=0
	
	
	while rs.%Next() {
		s className=rs.Get("ClassAllName")
		s tableName=rs.Get("TableName")
		s subScript=rs.Get("SubScriptString")
		s indexType=rs.Get("IndexType")
		
		s tmpPatIndex=tmpPatIndex+1 // 输出总数量
		set Data=$lb(className,tableName,subScript,indexType)
		if (indexType="data"){
			set DataResultTypeDataNew(tmpDataIndex)=Data
			set tmpDataIndex=tmpDataIndex+1
		}
		continue:indexType="data"
        set DataResultIndex(tmpIndexS)=Data	
        set tmpIndexS=tmpIndexS+1		
	}
	
	s data=##Class(%DynamicArray).%New()
	/// 首行的位置留给搜索框.
    s ObjOutData=##class(%DynamicObject).%New() 
    d ObjOutData.%Set("className","")
    d ObjOutData.%Set("tableName","")
    d ObjOutData.%Set("subScript","")
    d ObjOutData.%Set("indexType","")
    d data.%Push(ObjOutData)
    s result.Total=1
    s result.Data=data
    
	/// 数据为空则返回空
	q:tmpPatIndex=0 result.%ToJSON()
	
	s TotalNum=tmpPatIndex
    
    s startRow=(page-1)*rows+1
    s maxRow=startRow-1+rows
    i maxRow>TotalNum d
    .s maxRow=TotalNum
    
    b ; 0323
    s newIndex=0
    f x=0:1:tmpDataIndex d
    .s ItmGrpInfo=$g(DataResultTypeDataNew(x))
    .q:ItmGrpInfo=""
    .s DataResult(newIndex)=ItmGrpInfo
    .s newIndex=newIndex+1
    
    f y=0:1:tmpIndexS d
    .s ItmGrpInfo=$g(DataResultIndex(y))
    .q:ItmGrpInfo=""
    .s DataResult(newIndex)=ItmGrpInfo
    .s newIndex=newIndex+1
    
    i maxRow<=TotalNum d
    .f i=startRow:1:maxRow d
    ..s ItmGrpInfo=$g(DataResult(i))
    ..q:ItmGrpInfo=""
    ..s ObjOutData=##class(%DynamicObject).%New() 
    ..s className=$lg(ItmGrpInfo,1)
    ..s tableName=$lg(ItmGrpInfo,2)
    ..s subScript=$lg(ItmGrpInfo,3)
    ..s indexType=$lg(ItmGrpInfo,4)
    ..d ObjOutData.%Set("className",className)
    ..d ObjOutData.%Set("tableName",tableName)
    ..d ObjOutData.%Set("subScript",subScript)
    ..d ObjOutData.%Set("indexType",indexType)
    ..d data.%Push(ObjOutData)
    
    s result.Total=TotalNum
    s result.Data=data
    q result.%ToJSON()
}

}
