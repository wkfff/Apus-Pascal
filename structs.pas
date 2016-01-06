// This is universal unit containing implementation
// of basic structures on common types: trees, hashes etc...
// Copyright (C) 2002-2015 Ivan Polyacov, ivan@apus-software.com, cooler@tut.by

{$M-,H+,R-,Q-}
unit structs;
interface
 uses classes,MyServis;
type
 TErrorState=(
  esNoError       =  0,
  esEmpty         =  1,
  esNotFound      =  2,
  esNoMoreItems   =  3,
  esOverflow      =  4);


 // --------------------------------------
 // Structures of arbitrary items
 // --------------------------------------

 // Traversing modes
 TraverseMode=(ChildrenFirst, // Handle children, then root (depth-search)
               RootFirst,     // Handle root, then children (depth-search)
               byLevels);     // width-search (by levels)
 // Iterator for tree traverse
 // depth - item's depth (distance from root, for depth-search only)
 // item - TGenericTree object
 TTreeIterator=procedure(depth:integer;item:TObject);

 // Generic tree
 TGenericTree=class
  private
   parent:TGenericTree;
   selfIndex:integer; // index in parent's children list
   children:TList;
  public
   data:pointer;
   freeObjects:boolean; // treat data as objects and free them
   preserveOrder:boolean; // true if order of children must be preserved
   constructor Create(useObjects:boolean=false;useOrder:boolean=false);
   destructor Destroy; override;
   function GetParent:TGenericTree;
   function GetIndex:integer; // return index in parent's children list
   function GetChildrenCount:integer;
   function GetChild(index:integer):TGenericTree;
   // Add child to the end of the children list, return it's index
   function AddChild(item:pointer):integer;
   // Insert child item to specified position
   procedure InsertChild(item:pointer;index:integer);
   // Traverse this tree
   procedure Traverse(mode:TraverseMode;iterator:TTreeiterator);
 end;

 // --------------------------------------
 // Structures of comparable items
 // --------------------------------------
 // Base class for custom structures items
 TBaseItem=class
  value:integer;
  function Compare(item:TBaseItem):integer; virtual;
 end;
 // Container with integer key
 TIntItem=class(TBaseItem)
  data:pointer;
  constructor Create(key:integer;content:pointer);
 end;
 // Container with floating-point key
 TFloatItem=class(TBaseItem)
  value:double;
  data:pointer;
  constructor Create(key:double;content:pointer);
  function Compare(item:TBaseItem):integer; override;
 end;
 // Container with string key
 PString=^string;
 TStrItem=class(TBaseItem)
  value:PString;
  data:pointer;
  constructor Create(var key:string;content:pointer);
  function Compare(item:TBaseItem):integer; override;
 end;

 THeap=class
  items:array of TBaseItem;
  hSize,count:integer;  // can be readed: size of heap and count of elements
  lastError:TErrorState;    // status of the last operation
  constructor Create(HeapSize:integer); // Create a new heap with given capacity
  procedure Put(item:TBaseItem); // Put new item into heap
  function Get:TBaseItem; // Get item from the top of the heap
  destructor Destroy; override; // Destroy the heap (but not its elements if any!)
  destructor ClearAndDestroy; virtual; // Destroy heap and all its elements
 end;

 // INCOMPLETED CODE
 TTreeItem=class
  weight:integer;
  key:integer;
  data:pointer;
  left,right,parent:TTreeItem;
  function Compare(item:TTreeItem):integer;
 end;
 TTree=class
  root:TTreeItem;
  constructor Create;
  destructor Destroy; override;
 end;
 // END OF INCOMPLETED CODE

 // --------------------------------------
 // Hash structures
 // --------------------------------------
 THashItem=record
  key:^string;
  value:pointer;
 end;
 TCell=record
  items:array of THashItem;
  count,size:integer;
 end;
 // Hash String->Pointer (1:1) store pointers, DOESNT copy key strings, so this is good as auxiliary
 // structure to make an existing data storage faster 
 TStrHash=class
  Hcount,Hsize:integer;
  cells:array of TCell;
  LastError:TErrorState;
  constructor Create;
  constructor CreateSize(newsize:integer);
  procedure Put(var key:string;data:pointer);
  function Get(key:string):pointer;
  procedure Remove(key:string);
  function FirstKey:string;   // Start key enumeration (no hash operation allowed)
  function NextKey:string;    // Fetch next key (any operation will reset enumeration)
  destructor Destroy; override;
 private
  CurCell,CurItem:integer;
  function HashValue(str:string):integer;
 end;

 // Another hash: string->variant(s) (1:1 or 1:n)
 // Intended to STORE data, not just reference as TStrHash
 // Структура не отличается офигенной скоростью, но хорошо работает в не особо критичных местах
 TVariants=array of variant;
 THash=object
  keys:array of string;
  count:integer; // number of keys (can be less than length of keys array!)
  values:array of variant;
  vcount:integer; // number of values (can be less than length of values array!)
  constructor Init(allowMultiple:boolean=false); // or clear
  procedure Put(const key:string;value:variant;replace:boolean=false);
  function Get(const key:string):variant; // get value associated with the key, or Unassigned if none
  function GetAll(const key:string):TVariants; // get array of values
  function GetNext:variant; // get next value associated with the key, or Unassigned if none
  function AllKeys:StringArr;
  procedure SortKeys; // ключи без значений удаляются
 private
  simplemode:boolean; // простой режим - хранятся ТОЛЬКО ключи и значения, никаких ссылок и пр.
  multi:boolean; // допускается несколько значений для любого ключа
  // used in advanced mode
  links:array of integer; // ссылки на ключи по значению хэша (голова списка)
  next:array of integer; // для каждого ключа - ссылка на ключ с тем же хэшем (односвязный список)
  // used in multi mode
  vlinks:array of integer; // для каждого ключа - ссылка на значение
  vNext:array of integer; // для каждого значения - ссылка на следующее значение, принадлежащее тому же ключу
  lastIndex:integer;
  hMask:integer;
  function HashValue(const v:string):integer;
  function Find(const key:string):integer;
  procedure SwitchToAdvancedMode;
  procedure AddValue(const v:variant);
  procedure RemoveKey(index:integer);
  procedure BuildHash;
 end;

 // Another hash: variant->variants
{ TVarHash=object
  KeyCount:integer;
  constructor Init;
  procedure Add(key:variant;value:variant); // associate an item with the key
  procedure Replace(key:variant;value:variant); // associate only this item with the key (can be used to clear the key)
  function Get(key:variant;index:integer=0):variant; // get item for the key
  function Count(key:variant):integer; // how many items are associated with the key?
  function GetKey(index:integer):variant;
  procedure SortKeys;
 private
  keys,values:array of variant;
 end;}

 // Simple storage of "Key->Value" pairs where both key and value are 32bit integers (or compatible)
 // Returns -1 if there is no value for given key
 TSimpleHash=record
  keys,values:array of integer;
  count:integer; // must be used instead of Length!!!
  procedure Init(estimatedCount:integer);
  procedure Put(key,value:integer);
  function Get(key:integer):integer; // -1 if no value
  function HasValue(key:integer):boolean;
  procedure Remove(key:integer);
 private
  links:array of integer; // начало списка для каждого возможного значения хэша
  next:array of integer; // номер следующей пары с таким же хэшем ключа
  hMask:integer;
  fFree:integer; // начало списка свободных элементов (если есть)
  function HashValue(const k:integer):integer; inline;
 end;

 // Bit array
 TBitStream=record
  size:integer; // number of bits stored
  procedure Init(estimatedSize:integer=1000);
  procedure Put(var buf;count:integer); // append count bits to the stream
  procedure Get(var buf;count:integer); // read count bits from the stream (from readPos position)
  function SizeInBytes:integer; // return size of stream in bytes
 private
  capacity,readPos:integer;
  data:array of byte;
 end;

 // Simple list of variants
{ TSimpleList=record
  values:array of variant;
  procedure Add(v:variant);
 end;}

implementation
 uses SysUtils,variants;

{  constructor TVarHash.Init;
   begin
    KeyCount:=0;
    SetLength(keys,100);
    SetLength(values,100);
   end;

  procedure TVarHash.Add;
   begin
   end;

  procedure TVarHash.Replace(key:variant;value:variant);
   begin
   end;

  function TVarHash.Get(key:variant;index:integer=0):variant;
   begin
   end;

  function TVarHash.Count(key:variant):integer; 
   begin
   end;

  function TVarHash.GetKey(index:integer):variant;
   begin
   end;

  procedure TVarHash.SortKeys;
   begin
   end;  }


 function TBaseItem.Compare;
  begin
   if value>item.value then result:=1 else
    if value<item.value then result:=-1 else
     result:=0;
  end;

 constructor TIntItem.Create;
  begin
   value:=key;
   data:=content;
  end;

 constructor TFloatItem.Create;
  begin
   value:=key;
   data:=content;
  end;

 function TFloatItem.Compare;
  begin
   if not (item is TFloatItem) then exit;
   if value>(item as TFloatItem).value then result:=1 else
    if value<(item as TFloatItem).value then result:=-1 else
     result:=0;
  end;

 function TTreeItem.Compare;
  begin
    if key>item.key then result:=1 else
    if key<item.key then result:=-1 else
     result:=0;
  end;


 constructor TStrItem.Create;
  begin
   value:=addr(key);
   data:=content;
  end;

 function TStrItem.Compare;
  begin
   if not (item is TStrItem) then exit;
   if value^>(item as TStrItem).value^ then result:=1 else
    if value^<(item as TStrItem).value^ then result:=-1 else
     result:=0;
  end;

 constructor THeap.Create;
  begin
   hSize:=HeapSize+1;
   SetLength(items,hSize);
   count:=0; LastError:=esNoError;
  end;

 procedure THeap.Put;
  var
   p:integer;
  begin
   if count>hSize then begin
    LastError:=esOverflow;
    exit;
   end;
   inc(count);
   p:=count;
   while (p>1) and (item.compare(items[p div 2])<0) do begin
    items[p]:=items[p div 2];
    p:=p div 2;
   end;
   items[p]:=item;
   LastError:=esNoError;
  end;

 function THeap.Get;
  var
   p,p1,p2:integer;
  begin
   if count=0 then begin
    result:=nil;
    LastError:=esEmpty;
    exit;
   end;
   result:=items[1];
   dec(count);
   p:=1;
   repeat
    p1:=p*2;
    if p1>count then break;
    p2:=p1+1;
    if (p2<=count) and (items[p2].compare(items[p1])<0) then
      p1:=p2;
    if items[p1].compare(items[count+1])<0 then begin
     items[p]:=items[p1];
     p:=p1;
    end else break;
   until false;
   items[p]:=items[count+1];
   LastError:=esNoError;
  end;

 destructor THeap.Destroy;
  begin
   SetLength(items,0);
   count:=0;
  end;

 destructor THeap.ClearAndDestroy;
  var
   i:integer;
  begin
   for i:=1 to count do
    items[i].destroy;
   count:=0;
   SetLength(items,0);
  end;

 constructor TStrHash.Create;
  begin
   CreateSize(256);
  end;

 constructor TStrHash.CreateSize;
  var
   i:integer;
  begin
   Hsize:=newsize;
   SetLength(cells,Hsize);
   Hcount:=0;
   LastError:=esNoError;
   for i:=0 to Hsize-1 do begin
    cells[i].count:=0;
    cells[i].size:=1;
    SetLength(cells[i].items,1);
   end;
  end;

 function TStrHash.HashValue;
  var
   i,s:integer;
  begin
   s:=0;
   for i:=1 to length(str) do
    s:=s+byte(str[i]);
   result:=s mod Hsize;
  end;

 procedure TStrHash.Put;
  var
   h,i:integer;
  begin
   h:=HashValue(key);
   with cells[h] do begin
    for i:=0 to count-1 do
     if items[i].key^=key then begin
      items[i].value:=data;
      LastError:=esNoError;
      exit;
     end;
    if count=size then begin
     inc(size,8+size div 4);
     SetLength(items,size);
    end;
    items[count].key:=addr(key);
    items[count].value:=data;
    inc(count);
    inc(HCount);
   end;
   LastError:=esNoError;
  end;

 function TStrHash.Get;
  var
   h,i:integer;
  begin
   h:=HashValue(key);
   with cells[h] do begin
    for i:=0 to count-1 do
     if items[i].key^=key then begin
      LastError:=esNoError;
      result:=items[i].value;
      exit;
     end;
   end;
   result:=nil;
   LastError:=esNotFound;
  end;

 procedure TStrHash.Remove;
  var
   h,i:integer;
  begin
   h:=HashValue(key);
   with cells[h] do begin
    for i:=0 to count-1 do
     if items[i].key^=key then begin
      LastError:=esNoError;
      if count>i then
       items[i]:=items[count-1];
      dec(count);
      if size-count>8 then begin
       dec(size,8);
       SetLength(items,size);
      end;
      exit;
     end;
   end;
   LastError:=esNotFound;
  end;

 function TStrHash.FirstKey;
  begin
   CurCell:=0; CurItem:=0;
   if CurItem>=cells[curCell].count then begin
    repeat
     inc(CurCell);
     CurItem:=0;
     if cells[CurCell].count>0 then begin
      result:=NextKey;
      exit;
     end;
    until CurCell>=HSize;
   end else begin
    if curItem<cells[curCell].count then begin
     result:=cells[CurCell].items[CurItem].key^;
     inc(curItem);
    end else begin
     result:='';                     
     LastError:=esEmpty;
    end;
   end;
  end;

 function TStrHash.NextKey;
  begin
   result:='';
   if (CurCell<HSize) and (curItem<cells[curCell].count) then
    result:=cells[CurCell].items[CurItem].key^;
   inc(CurItem);
   if CurItem>=cells[curCell].count then
    repeat
     inc(CurCell);
     if curCell>=hSize then break;
     CurItem:=0;
     if cells[CurCell].count>0 then begin
      result:=cells[curCell].items[0].key^;
      inc(curItem);                          
      exit;
     end;
    until false;
   LastError:=esNoMoreItems;
  end;

 destructor TStrHash.Destroy;
  var
   i:integer;
  begin
   for i:=0 to Hsize-1 do begin
    SetLength(cells[i].items,0);
    cells[i].size:=0;
    cells[i].count:=0;
   end;
   SetLength(cells,0);
   Hcount:=0;
  end;

 constructor TTree.Create;
  begin
   root:=nil;
  end;

 destructor TTree.Destroy;
  begin
  end;

{ TGenericTree }

function TGenericTree.AddChild(item: pointer): integer;
 var
  t:TGenericTree;
begin
  t:=TGenerictree.Create(FreeObjects,PreserveOrder);
  t.data:=item;
  t.parent:=self;
  t.SelfIndex:=children.Count;
  result:=children.Add(t);
end;

constructor TGenericTree.Create;
begin
  parent:=nil;
  data:=nil;
  children:=TList.Create;
  FreeObjects:=UseObjects;
  PreserveOrder:=useOrder;
end;

destructor TGenericTree.Destroy;
 var
  o:TObject;
  item:TGenericTree;
  i:integer;
begin
  // Destroy children
  i:=0;
  while children.count>0 do begin
   item:=children[children.count-1];
   item.destroy;
  end;
  children.destroy;
  // Free object
  if FreeObjects then begin
   o:=data;
   o.Free;
  end;
  // Remove from parent's children
  if parent<>nil then begin
   if PreserveOrder then begin
    parent.children.Delete(SelfIndex);
    // Откорректировать SelfIndex для смещенных эл-тов
    for i:=SelfIndex to parent.children.Count-1 do begin
     item:=parent.children[i];
     item.SelfIndex:=i;
    end;
   end else begin
    // Удалить элемент заменив его последним
    parent.children.Move(parent.children.Count-1,SelfIndex);
    item:=parent.children[SelfIndex];
    item.SelfIndex:=SelfIndex;
   end;
  end;
  inherited;
end;

function TGenericTree.GetChild(index: integer): TGenericTree;
begin
 result:=children[index];
end;

function TGenericTree.GetChildrenCount: integer;
begin
 result:=children.count;
end;

function TGenericTree.GetIndex: integer;
begin
 result:=SelfIndex;
end;

function TGenericTree.GetParent: TGenericTree;
begin
 result:=parent;
end;

procedure TGenericTree.InsertChild(item: pointer; index: integer);
 var
  t,t2:TGenericTree;
  i:integer;
begin
  if index<0 then
   raise EError.Create('GenericTree: invalid index');
  if index>children.count then index:=children.count;
  t:=TGenerictree.Create(FreeObjects,PreserveOrder);
  t.data:=item;
  t.parent:=self;
  t.SelfIndex:=index;
  if PreserveOrder then begin
   children.Insert(index,item);
   for i:=index to children.count-1 do begin
    t:=children[i];
    t.selfIndex:=i;
   end;
  end else begin
   children.Add(nil);
   t2:=children[index];
   children[children.count-1]:=t2;
   t2.SelfIndex:=children.count-1;
   children[index]:=t;
  end;
end;

procedure TGenericTree.Traverse(mode: TraverseMode;
  iterator: TTreeiterator);

 // Depth-search: children, then root
 procedure DepthSearch(depth:integer;iterator:TTreeIterator;RootFirst:boolean);
  var
   i:integer;
 begin
   if RootFirst then
    iterator(depth,self);
   for i:=0 to children.count-1 do
    DepthSearch(depth+1,iterator,RootFirst);
   if not RootFirst then
    iterator(depth,self);
 end;
 // Width-search
 procedure WidthSearch;
  var
   queue:TList;
   index,i:integer;
   item:TGenericTree;
 begin
  queue:=TList.Create;
  queue.add(self);
  index:=0;
  while index<queue.Count do begin
   item:=queue[index];
   inc(index);
   iterator(0,item);
   for i:=0 to item.children.Count-1 do
    queue.Add(item.children[i]);
  end;
 end;

begin
 case mode of
  ChildrenFirst:DepthSearch(0,iterator,false);
  RootFirst:DepthSearch(0,iterator,true);
  ByLevels:WidthSearch;
 end;
end;

{ THash }
constructor THash.Init(allowMultiple:boolean=false);
 var
  i:integer;
 begin
  count:=0; vCount:=0;
  simplemode:=true;
  lastIndex:=-1;
  multi:=allowMultiple;
  SetLength(keys,32);
  if multi then begin
   SetLength(vLinks,32);
   SetLength(values,64);
   SetLength(vNext,64);
  end else
   SetLength(values,32);
 end;

function THash.Find(const key: string): integer;
 begin
  result:=links[HashValue(key)];
  while (result>=0) and (keys[result]<>key) do result:=next[result];
 end;

function THash.HashValue(const v: string): integer;
 var
  i:integer;
  st:string;
 begin
  result:=0;
  for i:=1 to length(v) do begin
//   inc(result,byte(v[i]));
   inc(result,byte(v[i]) shl (i and 3)); // 3 почему-то работает лучше всего...
  end;
  result:=result and hMask;
 end;

function THash.Get(const key: string): variant;
 var
  h,p:integer;
  index:integer;
 begin
  // 1. Find key index
  if simplemode then begin
   // simple mode
   index:=0;
   while (index<count) and (keys[index]<>key) do inc(index);
  end else
   index:=Find(key);
  // 2. Get value
  if (index>=0) and (index<count) then begin
   if multi then begin
    lastIndex:=vlinks[index];
    result:=values[lastIndex];
    lastIndex:=vNext[lastIndex];
   end else
    result:=values[index];
  end else
   result:=Unassigned;
 end;

function THash.GetNext:variant; // get next value associated with the key, or Unassigned if none
 begin
  if (lastIndex>=0) and (lastIndex<vCount) then begin
   result:=values[lastIndex];
   lastIndex:=vNext[lastIndex];
  end else
   result:=Unassigned;
 end;

function THash.GetAll(const key:string):TVariants; // get array of values
 var
  c:integer;
  v:variant;
 begin
  SetLength(result,10);
  c:=0;
  v:=Get(key);
  while not VarIsEmpty(v) do begin
   result[c]:=v;
   v:=getNext;
   inc(c);
   if c>=length(result) then
    SetLength(result,c*2);
  end;
  SetLength(result,c);
 end;

procedure THash.AddValue(const v:variant);
 var
  i:integer;
 begin
  if vCount>=length(values) then begin
   SetLength(values,vCount*2);
   SetLength(vNext,vCount*2);
   for i:=vCount to vCount*2-1 do
    vNext[i]:=-1;
  end;
  values[vCount]:=v;
 end;

procedure THash.RemoveKey(index:integer);
 var
  h,p:integer;
 begin
  if simplemode then
   keys[index]:=keys[count-1]
  else begin
   // Сперва скорректируем ссылки
   h:=HashValue(keys[index]);
   p:=links[h];
   if p=index then // удаление из начала списка
    links[h]:=next[p]
   else begin // есть предыдущий элемент
    while next[p]<>index do p:=next[p];
    next[p]:=next[index];
   end;
   // теперь нужно перенести последний элемент
   keys[index]:=keys[count-1];
   if multi then vlinks[index]:=vlinks[count-1];
   for p:=0 to count-2 do
    if next[p]=count-1 then begin
     next[p]:=index; break;
    end;
  end;
  dec(count);
  if multi then begin
   // удалить все значения
  end else begin
   values[index]:=values[vCount-1];
   dec(vCount);
  end;
 end;

procedure THash.Put(const key:string; value:variant; replace:boolean=false);
 var
  h,p,index,j,size:integer;
 begin
  // Find key index
  if simplemode then begin
   index:=0;
   while (index<count) and (keys[index]<>key) do inc(index);
  end else begin
   index:=Find(key);
   if index<0 then index:=count;
  end;
   
  // Add new key?
  if index=count then
   if simplemode then begin
    keys[index]:=key;
    if multi then vlinks[index]:=-1;
    inc(count);
    if count=6 then SwitchToAdvancedMode;
   end else begin // Advanced (indexed) mode
    if count>=length(keys) then begin
     size:=length(keys)*2+32; // 32 -> 96 ->224 -> 480 -> 992 -> ...
     SetLength(keys,size);
     SetLength(next,size);
     if multi then SetLength(vLinks,size);
     if count>length(links)+32 then begin
      hMask:=(hMask shl 2) or $F;
      SetLength(links,length(links)*4);
      BuildHash;
     end;
    end;
    h:=HashValue(key);
    next[count]:=links[h];
    links[h]:=count;
    keys[count]:=key;
    if multi then vLinks[count]:=-1;
    index:=count;
    inc(count);
   end;
  // Add value
  if multi then begin
   // add new value
   AddValue(value);
   vNext[vCount]:=vLinks[index];
   vLinks[index]:=vCount;
   inc(vCount);
  end else begin
   if vCount>=length(values) then SetLength(values,vCount*2);
   values[index]:=value; // fixed index
   vCount:=count;
  end;
 end;

procedure THash.SwitchToAdvancedMode;
 var
  i,h:integer;
 begin
  simpleMode:=false;
  SetLength(next,length(keys));
  SetLength(links,64);
  hMask:=$3F;
  BuildHash;
 end;

procedure THash.BuildHash;
 var
  i,h:integer;
 begin
  for i:=0 to High(links) do links[i]:=-1;
  for i:=0 to count-1 do next[i]:=-1;
  for i:=0 to count-1 do begin
   h:=HashValue(keys[i]);
   next[i]:=links[h];
   links[h]:=i;
  end;
 end;

function THash.AllKeys:StringArr;
 var
  i:integer;
 begin
  SetLength(result,count);
  for i:=0 to count-1 do
   result[i]:=keys[i];
 end;

procedure THash.SortKeys;
 procedure QuickSort(a,b:integer);
  var
   lo,hi,v:integer;
   mid,key:string;
   vr:variant;
   i,j:integer;
  begin
   lo:=a; hi:=b;
   mid:=keys[(a+b) div 2];
   repeat
    while keys[lo]<mid do inc(lo);
    while keys[hi]>mid do dec(hi);
    if lo<=hi then begin
     key:=keys[lo];
     keys[lo]:=keys[hi];
     keys[hi]:=key;
     if multi then begin
      v:=vLinks[lo];
      vLinks[lo]:=vLinks[hi];
      vLinks[hi]:=v;
     end else begin
      vr:=values[lo];
      values[lo]:=values[hi];
      values[hi]:=vr;
     end;
     inc(lo);
     dec(hi);
    end;
   until lo>hi;
   if hi>a then QuickSort(a,hi);
   if lo<b then QuickSort(lo,b);
  end;
 begin
  if count<2 then exit;
  // 1. Sort keys
  QuickSort(0,count-1);
  // 2. Restore hashes
  if not simplemode then BuildHash;
 end;

 // -------------------------------------------
 // TSimpleHash
 // -------------------------------------------

 procedure TSimpleHash.Init(estimatedCount:integer);
  var
   i:integer;
  begin
   SetLength(keys,estimatedCount);
   SetLength(values,estimatedCount);
   SetLength(next,estimatedCount);
   count:=0; fFree:=-1;
   hMask:=$FFF;
   while (hMask>estimatedCount) and (hMask>$1F) do hMask:=hMask shr 1;
   SetLength(links,hMask+1);
   for i:=0 to hMask do links[i]:=-1;
  end;

 procedure TSimpleHash.Put(key,value:integer);
  var
   h,i,n:integer;
  begin
   if fFree>=0 then begin
    // берем элемент из списка свободных
    i:=fFree; fFree:=next[fFree];
   end else begin
    // добавляем новый элемент
    i:=count; inc(count);
    if count>length(keys) then begin
     n:=length(keys)*2+64;
     SetLength(keys,n);
     SetLength(values,n);
     SetLength(next,n);
    end;
   end;
   // Store data
   keys[i]:=key;
   values[i]:=value;
   // Add to hash
   h:=HashValue(key);
   next[i]:=links[h];
   links[h]:=i;
  end;

 function TSimpleHash.Get(key:integer):integer;
  var
   h,i:integer;
  begin
   h:=HashValue(key);
   i:=links[h];
   while (i>=0) and (keys[i]<>key) do i:=next[i];
   if i>=0 then result:=values[i] else result:=-1;
  end;

 function TSimpleHash.HasValue(key:integer):boolean;
  var
   h,i:integer;
  begin
   h:=HashValue(key);
   i:=links[h];
   while (i>=0) and (keys[i]<>key) do i:=next[i];
   if i>=0 then result:=true else result:=false;
  end;

 procedure TSimpleHash.Remove(key:integer);
  var
   h,i,prev:integer;
  begin
   h:=HashValue(key);
   // Поиск по списку
   i:=links[h]; prev:=-1;
   while (i>=0) and (keys[i]<>key) do begin
    prev:=i;
    i:=next[i];
   end;
   if i>=0 then begin
    // Удаление из односвязного списка
    if prev>=0 then next[prev]:=next[i]
     else links[h]:=next[i];
    keys[i]:=-1; values[i]:=-1; 
    next[i]:=fFree;
    fFree:=i;
   end;
  end;

 function TSimpleHash.HashValue(const k:integer):integer;
  begin
   result:=(k+(k shr 11)+(k shr 23)) and hMask;
  end;

// -------------------------------------------------------
// TBitStream
// -------------------------------------------------------

 procedure TBitStream.Init;
  begin
   size:=0; readPos:=0;
   SetLength(data,estimatedSize div 8);
   capacity:=length(data)*8;
   FillChar(data[0],length(data),0);
  end;

 procedure TBitStream.Put(var buf;count:integer); // write count bits to the stream (from curPos position)
  var
   pb:PByte;
   i:integer;
   b:byte;
  begin
   if size+count>capacity then begin
    i:=length(data);
    capacity:=(capacity+1024)*2;
    SetLength(data,capacity div 8);
    FillChar(data[i],length(data)-i,0); // zerofill 
   end;
   pb:=@buf; b:=pb^;
   // простая, неэффективная версия
   for i:=0 to count-1 do begin
    if b and 1>0 then
     data[size shr 3]:=data[size shr 3] or (1 shl (i and 7));
    b:=b shr 1;
    inc(size);
    if i and 7=7 then begin
     inc(pb); b:=pb^;
    end;
   end;
  end;

 procedure TBitStream.Get(var buf;count:integer); // read count bits from the stream (from curPos position)
  var
   pb:PByte;
   b:byte;
  begin
   // простая, неэффективная версия

  end;

 function TBitStream.SizeInBytes:integer; // return size of stream in bytes
  begin
   result:=(size+7) div 8;
  end;

end.
