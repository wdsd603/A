part of pica_settings;

class ComicSourceSettings extends StatefulWidget {
  const ComicSourceSettings({super.key});

  @override
  State<ComicSourceSettings> createState() => _ComicSourceSettingsState();
}

class _ComicSourceSettingsState extends State<ComicSourceSettings> {
  var url = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildCard(context),
        const PicacgSettings(false),
        const Divider(),
        const EhSettings(false),
        const Divider(),
        const JmSettings(false),
        const Divider(),
        const HtSettings(false),
        for(var source in ComicSource.sources)
          buildCustom(context, source),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
      ],
    );
  }

  Widget buildCustom(BuildContext context, ComicSource source){
    return Column(
      children: [
        const Divider(),
        ListTile(
          title: Text(source.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(App.isWindows)
                IconButton(onPressed: () => edit(source), icon: const Icon(Icons.edit_note)),
              IconButton(onPressed: () => update(source), icon: const Icon(Icons.update)),
              IconButton(onPressed: () => delete(source), icon: const Icon(Icons.delete)),
            ],
          ),
        ),
      ],
    );
  }

  void delete(ComicSource source){
    var file = File(source.filePath);
    file.delete();
    ComicSource.sources.remove(source);
    MyApp.updater?.call();
  }

  void edit(ComicSource source) async{
    try {
      await Process.run("code", [source.filePath], runInShell: true);
      await showDialog(context: App.globalContext!, builder: (context) => AlertDialog(
        title: const Text("Reload Configs"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("cancel")),
          TextButton(onPressed: () {
            ComicSource.reload();
            MyApp.updater?.call();
          }, child: const Text("continue")),
        ],
      ));
    }
    catch(e){
      print(e);
      showToast(message: "Failed to launch vscode");
    }
  }

  void update(ComicSource source) async{
    ComicSource.sources.remove(source);
    if (!source.url.isURL) {
      showMessage(null, "Invalid url config");
    }
    bool cancel = false;
    var controller = showLoadingDialog(App.globalContext!, () => cancel = true, false);
    try {
      var res = await logDio().get<String>(source.url,
          options: Options(responseType: ResponseType.plain));
      if(cancel)  return;
      controller.close();
      var newSource = await ComicSourceParser().parse(res.data!, source.filePath);
      ComicSource.sources.add(newSource);
      File(source.filePath).writeAsString(res.data!);
      MyApp.updater?.call();
    }
    catch(e){
      if(cancel)  return;
      showMessage(null, e.toString());
    }
  }

  Widget buildCard(BuildContext context){
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(title: Text("添加漫画源".tl), leading: const Icon(Icons.dashboard_customize),),
            TextField(
              decoration: InputDecoration(
                hintText: "URL",
                border: const UnderlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffix: IconButton(onPressed: () => handleAddSource(url), icon: const Icon(Icons.check))
              ),
              onChanged: (value){
                url = value;
              },
              onSubmitted: handleAddSource
            ).paddingHorizontal(16).paddingBottom(16),
            Row(
              children: [
                TextButton(onPressed: chooseFile, child: Text("选择文件".tl)).paddingLeft(8),
                const Spacer(),
                TextButton(onPressed: help, child: Text("帮助".tl)).paddingRight(8),
              ],
            )
          ],
        ),
      ),
    ).paddingHorizontal(12);
  }

  void chooseFile() async{
    const XTypeGroup typeGroup = XTypeGroup(
      extensions: <String>['toml'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if(file == null)  return;
    try{
      await addSource(await file.readAsString(), file.name);
    }
    catch(e){
      showMessage(null, e.toString());
    }
  }

  void help(){

  }

  void handleAddSource(String url) async{
    if (url.isEmpty) {
      return;
    }
    var splits = url.split("/");
    splits.removeWhere((element) => element == "");
    var fileName = splits.last;
    bool cancel = false;
    var controller = showLoadingDialog(App.globalContext!, () => cancel = true, false);
    try {
      var res = await logDio().get<String>(url,
          options: Options(responseType: ResponseType.plain));
      if(cancel)  return;
      controller.close();
      await addSource(res.data!, fileName);
    }
    catch(e){
      if(cancel)  return;
      showMessage(null, e.toString());
    }
  }

  Future<void> addSource(String toml, String fileName) async{
    var comicSource = await ComicSourceParser().createAndParse(toml, fileName);
    ComicSource.sources.add(comicSource);
    MyApp.updater?.call();
  }
}