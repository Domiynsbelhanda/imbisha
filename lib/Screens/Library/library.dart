import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import 'package:imbisha/Screens/Library/liked.dart';
import 'package:imbisha/Screens/LocalMusic/downed_songs.dart';
import 'package:imbisha/Screens/LocalMusic/downed_songs_desktop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

import '../../CustomWidgets/on_hover.dart';
import '../../Helpers/audio_query.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {

  final Map<String, List<SongModel>> _albums = {};
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  List<SongModel> _songs = [];
  String? tempPath = Hive.box('settings').get('tempDirPath')?.toString();
  final List<String> _sortedAlbumKeysList = [];

  bool added = false;
  int albumSortValue =
    Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;
  int minDuration =
    Hive.box('settings').get('minDuration', defaultValue: 10) as int;
  bool includeOrExclude =
    Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool;
  List includedExcludedPaths = Hive.box('settings')
      .get('includedExcludedPaths', defaultValue: []) as List;

  final Map<int, SongSortType> songSortTypes = {
    0: SongSortType.DISPLAY_NAME,
    1: SongSortType.DATE_ADDED,
    2: SongSortType.ALBUM,
    3: SongSortType.ARTIST,
    4: SongSortType.DURATION,
    5: SongSortType.SIZE,
  };

  final Map<int, OrderType> songOrderTypes = {
    0: OrderType.ASC_OR_SMALLER,
    1: OrderType.DESC_OR_GREATER,
  };

  @override
  void initState() {
    getData();
    super.initState();
  }

  bool checkIncludedOrExcluded(SongModel song) {
    for (final path in includedExcludedPaths) {
      if (song.data.contains(path.toString())) return true;
    }
    return false;
  }

  Future<void> getData() async {
    await offlineAudioQuery.requestPermission();
    tempPath ??= (await getTemporaryDirectory()).path;

      _songs = (await offlineAudioQuery.getSongs(
        sortType: songSortTypes[1],
        orderType: songOrderTypes[1],
      ))
          .where(
            (i) =>
        (i.duration ?? 60000) > 1000 * minDuration &&
            (i.isMusic! || i.isPodcast! || i.isAudioBook!) &&
            (includeOrExclude
                ? checkIncludedOrExcluded(i)
                : !checkIncludedOrExcluded(i)),
      )
          .toList();
    added = true;
    setState(() {});
    for (int i = 0; i < _songs.length; i++) {
      try {
        if (_albums.containsKey(_songs[i].album ?? 'Unknown')) {
          _albums[_songs[i].album ?? 'Unknown']!.add(_songs[i]);
        } else {
          _albums.addEntries([
            MapEntry(_songs[i].album ?? 'Unknown', [_songs[i]])
          ]);
          _sortedAlbumKeysList.add(_songs[i].album!);
        }

      } catch (e) {

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        AppBar(
          title: Text(
            AppLocalizations.of(context)!.library,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.nowPlaying,
          icon: Icons.queue_music_rounded,
          onTap: () {
            Navigator.pushNamed(context, '/nowplaying');
          },
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.lastSession,
          icon: Icons.history_rounded,
          onTap: () {
            Navigator.pushNamed(context, '/recent');
          },
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.favorites,
          icon: Icons.favorite_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LikedSongs(
                  playlistName: 'Son Favoris',
                  showName: AppLocalizations.of(context)!.favSongs,
                ),
              ),
            );
          },
        ),
        if (!Platform.isIOS)
          LibraryTile(
            title: AppLocalizations.of(context)!.myMusic,
            icon: MdiIcons.folderMusic,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => (Platform.isWindows || Platform.isLinux)
                      ? const DownloadedSongsDesktop()
                      : const DownloadedSongs(
                          showPlaylists: true,
                        ),
                ),
              );
            },
          ),
        LibraryTile(
          title: AppLocalizations.of(context)!.downs,
          icon: Icons.download_done_rounded,
          onTap: () {
            Navigator.pushNamed(context, '/downloads');
          },
        ),
        LibraryTile(
          title: AppLocalizations.of(context)!.playlists,
          icon: Icons.playlist_play_rounded,
          onTap: () {
            Navigator.pushNamed(context, '/playlists');
          },
        ),

        Container(
          padding: const EdgeInsets.all(16.0),
          child: AlbumsTab(
            albums: _albums,
            albumsList: _sortedAlbumKeysList,
            tempPath: tempPath!,
          ),
        )
      ],
    );
  }
}

class LibraryTile extends StatelessWidget {
  const LibraryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      leading: Icon(
        icon,
        color: Theme.of(context).iconTheme.color,
      ),
      onTap: onTap,
    );
  }
}

class AlbumsTab extends StatefulWidget {
  final Map<String, List<SongModel>> albums;
  final List<String> albumsList;
  final String tempPath;
  const AlbumsTab({
    super.key,
    required this.albums,
    required this.albumsList,
    required this.tempPath,
  });

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double boxSize =
    MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
        ? MediaQuery.of(context).size.width / 2
        : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;
    return SizedBox(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 1.65 / 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20),
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        shrinkWrap: true,
        itemCount: widget.albumsList.length < 20 ? widget.albumsList.length : 20,
        itemBuilder: (context, index) {
          return GestureDetector(
            child: Container(
              width: boxSize - 30,
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox.square(
                      dimension: boxSize - 30,
                      child: FutureBuilder(
                        builder: (context, element){

                          try{
                            return Image(
                              image: FileImage(
                                  File(
                                      '${widget.tempPath}/${widget.albums[widget.albumsList[index]]![0].displayNameWOExt}.jpg'
                                  )
                              ),
                            );
                          } catch(e) {
                            return const Image(
                              image: AssetImage(
                                'assets/album.png',
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 4.0,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.albumsList[index],
                            textAlign: TextAlign.start,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${widget.albums[widget.albumsList[index]]!.length} ${AppLocalizations.of(context)!.songs}',
                            textAlign: TextAlign.center,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .textTheme
                                  .caption!
                                  .color,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DownloadedSongs(
                    title: widget.albumsList[index],
                    cachedSongs: widget.albums[widget.albumsList[index]],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}