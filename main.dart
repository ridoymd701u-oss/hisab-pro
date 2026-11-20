import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const HisabProApp());

class Txn {
  final String id, title, category, type, date;
  final double amount;
  Txn({required this.id, required this.title, required this.category,
    required this.type, required this.date, required this.amount});
  Map<String, dynamic> toJson() => {'id':id,'title':title,'category':category,
    'type':type,'date':date,'amount':amount};
  factory Txn.fromJson(Map<String,dynamic> j) => Txn(
    id:j['id'], title:j['title'], category:j['category'], type:j['type'],
    date:j['date'], amount:(j['amount'] as num).toDouble());
}

class HisabProApp extends StatelessWidget {
  const HisabProApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HISAB PRO',
    theme: ThemeData(useMaterial3:true, colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF13A88A), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0B1422),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101E30),
        foregroundColor: Colors.white)),
    home: const HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState()=>_HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab=0;
  DateTime selected=DateTime.now();
  List<Txn> txns=[];
  final prefsKey='hisab_pro_txns';

  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    final raw=p.getString(prefsKey);
    if(raw!=null){setState(()=>txns=(jsonDecode(raw) as List)
      .map((e)=>Txn.fromJson(e)).toList());}
  }
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString(prefsKey,jsonEncode(txns.map((e)=>e.toJson()).toList()));
  }
  double get income=>txns.where((e)=>e.type=='আয়').fold(0,(s,e)=>s+e.amount);
  double get expense=>txns.where((e)=>e.type=='খরচ').fold(0,(s,e)=>s+e.amount);
  List<Txn> get todayTxns=>txns.where((e)=>e.date==DateFormat('yyyy-MM-dd').format(selected)).toList();

  @override Widget build(BuildContext context){
    final pages=[dashboard(), calendar(), ledger(), tools(), profile()];
    return Scaffold(
      appBar: AppBar(title: const Row(children:[
        Icon(Icons.calendar_month,color:Color(0xFF62E0C2)),
        SizedBox(width:9), Text('HISAB PRO',style:TextStyle(fontWeight:FontWeight.bold,letterSpacing:1.2))
      ]), actions:[IconButton(onPressed:()=>setState(()=>tab=4),icon:const Icon(Icons.settings))]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex:tab, onDestinationSelected:(v)=>setState(()=>tab=v),
        destinations: const [
          NavigationDestination(icon:Icon(Icons.home_outlined),label:'হোম'),
          NavigationDestination(icon:Icon(Icons.calendar_month),label:'ক্যালেন্ডার'),
          NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),label:'হিসাব'),
          NavigationDestination(icon:Icon(Icons.calculate_outlined),label:'টুলস'),
          NavigationDestination(icon:Icon(Icons.person_outline),label:'প্রোফাইল'),
        ]),
      floatingActionButton: tab==0||tab==1||tab==2 ? FloatingActionButton.extended(
        onPressed:addTxn,icon:const Icon(Icons.add),label:const Text('লেনদেন যোগ')):null,
    );
  }

  Widget dashboard()=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
      style:const TextStyle(color:Colors.white70)),
    const SizedBox(height:14),
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(
      gradient:const LinearGradient(colors:[Color(0xFF116B62),Color(0xFF173C58)]),
      borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('আনুমানিক হাতে থাকা টাকা',style:TextStyle(color:Colors.white70)),
        const SizedBox(height:8),Text(money(income-expense),
          style:const TextStyle(fontSize:32,fontWeight:FontWeight.bold,color:Colors.white)),
        const SizedBox(height:5),const Text('মোট আয় − মোট খরচ',style:TextStyle(color:Colors.white70))
      ])),
    const SizedBox(height:14),
    Row(children:[
      Expanded(child:statCard('মোট আয়',income,Icons.trending_up,const Color(0xFF1D795B))),
      const SizedBox(width:10),
      Expanded(child:statCard('মোট খরচ',expense,Icons.trending_down,const Color(0xFF813F4A))),
    ]),
    const SizedBox(height:10),
    Row(children:[
      Expanded(child:statCard('নেট ব্যালেন্স',income-expense,Icons.account_balance,const Color(0xFF315A83))),
      const SizedBox(width:10),
      Expanded(child:statCard('লেনদেন',txns.length.toDouble(),Icons.receipt_long,const Color(0xFF58477D),currency:false)),
    ]),
    const SizedBox(height:22),
    const Text('সাম্প্রতিক লেনদেন',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    if(txns.isEmpty) empty('এখনো কোনো লেনদেন নেই। + বাটনে চাপ দিয়ে শুরু করুন।')
    else ...txns.reversed.take(5).map(txnTile)
  ]);

  Widget statCard(String title,double value,IconData icon,Color color,{bool currency=true})=>
    Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(
      color:color.withOpacity(.18),borderRadius:BorderRadius.circular(18),
      border:Border.all(color:color.withOpacity(.5))),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(icon,color:color==const Color(0xFF1D795B)?const Color(0xFF67E2B0):Colors.white70),
        const SizedBox(height:10),Text(title,style:const TextStyle(color:Colors.white70)),
        const SizedBox(height:4),Text(currency?money(value):value.toInt().toString(),
          style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))
      ]));

  Widget calendar()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('ক্যালেন্ডার',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:10),
    CalendarDatePicker(initialDate:selected,firstDate:DateTime(2000),lastDate:DateTime(2100),
      onDateChanged:(d)=>setState(()=>selected=d)),
    Card(color:const Color(0xFF14243A),child:Padding(padding:const EdgeInsets.all(16),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(DateFormat('d MMMM yyyy, EEEE').format(selected),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        const SizedBox(height:5),Text('তারিখ: ${DateFormat('yyyy-MM-dd').format(selected)}',
          style:const TextStyle(color:Colors.white70)),
        const Divider(height:24),
        Text('এই দিনের লেনদেন (${todayTxns.length})'),
        if(todayTxns.isEmpty) const Padding(padding:EdgeInsets.all(12),child:Text('এই তারিখে কোনো হিসাব নেই।'))
        else ...todayTxns.map(txnTile),
        Align(alignment:Alignment.centerRight,child:TextButton.icon(
          onPressed:addTxn,icon:const Icon(Icons.add),label:const Text('এই তারিখে হিসাব যোগ করুন')))
      ])))
  ]);

  Widget ledger()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('সব লেনদেন',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:10),
    if(txns.isEmpty) empty('আয় বা খরচ যোগ করলে এখানে দেখা যাবে।')
    else ...txns.reversed.map(txnTile)
  ]);

  Widget txnTile(Txn t)=>Card(color:const Color(0xFF14243A),child:ListTile(
    leading:CircleAvatar(backgroundColor:t.type=='আয়'?Colors.green.withOpacity(.2):Colors.red.withOpacity(.2),
      child:Icon(t.type=='আয়'?Icons.add:Icons.remove,color:t.type=='আয়'?Colors.greenAccent:Colors.redAccent)),
    title:Text(t.title),subtitle:Text('${t.category} • ${t.date}'),
    trailing:Text('${t.type=='আয়'?'+':'−'} ${money(t.amount)}',
      style:TextStyle(color:t.type=='আয়'?Colors.greenAccent:Colors.redAccent,fontWeight:FontWeight.bold)),
    onLongPress:()=>deleteTxn(t)));

  Widget tools()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('স্মার্ট টুলস',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:12),
    toolTile(Icons.calculate,'ক্যালকুলেটর','সাধারণ হিসাব করুন',calculator),
    toolTile(Icons.currency_exchange,'কারেন্সি কনভার্টার','নিজে এক্সচেঞ্জ রেট লিখে রূপান্তর করুন',currency),
    toolTile(Icons.handshake,'দেনা-পাওনা','ব্যক্তি ও টাকার হিসাব রাখুন',()=>showInfo('দেনা-পাওনা','পরবর্তী সংস্করণে ব্যক্তি, ফোন নম্বর, পাওনা, দেনা ও আংশিক পরিশোধের পূর্ণ লেজার যুক্ত হবে।')),
    toolTile(Icons.savings,'সঞ্চয় লক্ষ্য','লক্ষ্যভিত্তিক সঞ্চয়',()=>showInfo('সঞ্চয়','পরবর্তী সংস্করণে সঞ্চয় লক্ষ্য ও অগ্রগতি যুক্ত হবে।')),
    toolTile(Icons.bar_chart,'রিপোর্ট','মাসিক ও বার্ষিক রিপোর্ট',()=>showInfo('রিপোর্ট','লেনদেনের ডেটা এই স্টার্টার অ্যাপে ফোনে সংরক্ষিত হয়। PDF/Excel রিপোর্ট পরবর্তী ধাপ।')),
  ]);

  Widget toolTile(IconData i,String title,String sub,VoidCallback tap)=>Card(
    color:const Color(0xFF14243A),child:ListTile(leading:Icon(i,color:const Color(0xFF62E0C2)),
      title:Text(title),subtitle:Text(sub),trailing:const Icon(Icons.chevron_right),onTap:tap));

  Widget profile()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('প্রোফাইল ও যোগাযোগ',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:14),
    const ListTile(leading:Icon(Icons.phone),title:Text('মোবাইল যোগাযোগ'),subtitle:Text('01323551421')),
    const ListTile(leading:Icon(Icons.chat,color:Colors.green),title:Text('WhatsApp Support'),subtitle:Text('01904300036')),
    FilledButton.icon(onPressed:()=>launch('tel:01323551421'),icon:const Icon(Icons.call),label:const Text('ফোন করুন')),
    const SizedBox(height:8),
    FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:Colors.green.shade700),
      onPressed:()=>launch('https://wa.me/8801904300036'),
      icon:const Icon(Icons.chat),label:const Text('WhatsApp-এ যোগাযোগ করুন')),
    const Divider(height:30),
    const ListTile(leading:Icon(Icons.lock),title:Text('গোপনীয়তা'),subtitle:Text('আপনার হিসাব এই ডিভাইসে সংরক্ষিত থাকে।')),
    const ListTile(leading:Icon(Icons.info_outline),title:Text('সংস্করণ'),subtitle:Text('HISAB PRO Starter 1.0.0')),
  ]);

  Future<void> addTxn() async {
    final title=TextEditingController(), amount=TextEditingController(), category=TextEditingController();
    String type='আয়';
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:const Text('নতুন লেনদেন'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        SegmentedButton<String>(segments:const [ButtonSegment(value:'আয়',label:Text('আয়')),ButtonSegment(value:'খরচ',label:Text('খরচ'))],
          selected:{type},onSelectionChanged:(s)=>setD(()=>type=s.first)),
        TextField(controller:title,decoration:const InputDecoration(labelText:'বিবরণ')),
        TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'টাকার পরিমাণ')),
        TextField(controller:category,decoration:const InputDecoration(labelText:'ক্যাটাগরি (যেমন বাজার/বেতন)')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('বাতিল')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('সংরক্ষণ'))])));
    if(ok==true&&title.text.trim().isNotEmpty&&(double.tryParse(amount.text)??0)>0){
      setState(()=>txns.add(Txn(id:DateTime.now().microsecondsSinceEpoch.toString(),
        title:title.text.trim(),category:category.text.trim().isEmpty?'অন্যান্য':category.text.trim(),
        type:type,date:DateFormat('yyyy-MM-dd').format(selected),amount:double.parse(amount.text))));
      await save();
    }
  }
  Future<void> deleteTxn(Txn t) async {
    final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('লেনদেন মুছবেন?'),content:Text(t.title),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('না')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('মুছুন'))]));
    if(yes==true){setState(()=>txns.removeWhere((e)=>e.id==t.id));await save();}
  }
  void calculator(){
    final a=TextEditingController(),b=TextEditingController();
    String op='+';
    showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:const Text('স্মার্ট ক্যালকুলেটর'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'প্রথম সংখ্যা')),
        DropdownButton<String>(value:op,items:['+','−','×','÷','%'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setD(()=>op=v!)),
        TextField(controller:b,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'দ্বিতীয় সংখ্যা')),
        const SizedBox(height:12),
        ElevatedButton(onPressed:(){final x=double.tryParse(a.text)??0,y=double.tryParse(b.text)??0;
          double r=op=='+'?x+y:op=='−'?x-y:op=='×'?x*y:op=='÷'?(y==0?0:x/y):x*y/100;
          showInfo('ফলাফল',r.toStringAsFixed(2));},child:const Text('হিসাব করুন'))
      ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('বন্ধ'))])));
  }
  void currency(){
    final amount=TextEditingController(text:'1'), rate=TextEditingController(text:'120');
    showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('কারেন্সি → BDT'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'বিদেশি মুদ্রার পরিমাণ')),
        TextField(controller:rate,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'১ ইউনিটের BDT রেট')),
        const SizedBox(height:8),const Text('রেট নিজে যাচাই করে লিখুন; এটি লাইভ রেট নয়।')
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('বন্ধ')),
        FilledButton(onPressed:(){final v=(double.tryParse(amount.text)??0)*(double.tryParse(rate.text)??0);
          Navigator.pop(ctx);showInfo('বাংলাদেশি টাকা',money(v));},child:const Text('রূপান্তর'))]));
  }
  void showInfo(String title,String message)=>showDialog(context:context,builder:(c)=>AlertDialog(
    title:Text(title),content:Text(message),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('ঠিক আছে'))]));
  Widget empty(String s)=>Padding(padding:const EdgeInsets.all(22),child:Center(child:Text(s,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white60))));
  String money(double v)=>'৳ ${NumberFormat('#,##0.##').format(v)}';
  Future<void> launch(String url) async {
    final uri=Uri.parse(url);
    if(!await launchUrl(uri,mode:LaunchMode.externalApplication)&&mounted){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('লিংক খোলা যায়নি।')));
    }
  }
}
