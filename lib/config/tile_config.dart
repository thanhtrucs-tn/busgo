// tile_config.dart
// Cấu hình TẬP TRUNG cho nguồn bản đồ (tile provider).
//
// Mục đích:
//  - Không hardcode URL/attribution trực tiếp trong Widget.
//  - Tách riêng URL tile, tên gói User-Agent và attribution.
//  - Mặc định dùng Esri World Street Map (chạy ổn định, không cần API key),
//    đồng thời cấu hình sẵn OpenStreetMap để chuyển sau này khi cần.
//
// Đổi nguồn tile: chỉ cần sửa giá trị của `current` (vd: TileConfig.osm),
// toàn bộ màn hình bản đồ sẽ dùng theo mà không phải chỉnh từng chỗ.

// Đại diện một nguồn tile.
class TileProviderConfig {
  const TileProviderConfig({
    required this.id,
    required this.displayName,
    required this.urlTemplate,
    required this.attribution,
    required this.userAgentPackageName,
  });

  // Nhận diện (vd: 'esri', 'osm') - tùy chọn, giúp dễ theo dõi/log.
  final String id;

  // Tên hiển thị cho mục đích ghi chú/tùy chọn.
  final String displayName;

  // URL gốc tile. flutter_map thay {z}/{x}/{y} bằng tọa độ tile.
  final String urlTemplate;

  // Dòng ghi công/nguồn bản đồ hiển thị trên bản đồ (attribution).
  // Esri World Street Map lấy dữ liệu của Esri (tùy tầng), không chỉ của OSM,
  // nên attribution ghi rõ nguồn Esri để đúng với tile đang dùng.
  final String attribution;

  // Tên gói gửi qua User-Agent để máy chủ tile nhận diện ứng dụng
  // (không bị chặn khi tải tile).
  final String userAgentPackageName;
}

// Nơi chứa các nguồn tile + lựa chọn mặc định.
class TileConfig {
  // Lớp tĩnh: không cho khởi tạo.
  TileConfig._();

  // Nguồn tile ĐANG dùng. Muốn chuyển sang OSM đổi dòng này thành:
  //   static final TileProviderConfig current = TileConfig.osm;
  static final TileProviderConfig current = TileConfig.esri;

  // Esri World Street Map - mặc định (miễn phí, không cần API key,
  // chạy ổn định trên máy/simulator).
  static const TileProviderConfig esri = TileProviderConfig(
    id: 'esri',
    displayName: 'Esri World Street Map',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    attribution: 'Bản đồ © Esri — World Street Map',
    userAgentPackageName: 'com.example.busgo',
  );

  // OpenStreetMap - phương án dự phòng, dùng khi muốn thử OSM.
  // Lưu ý mục 4 yêu cầu: attribution bắt buộc ghi "© OpenStreetMap contributors".
  static const TileProviderConfig osm = TileProviderConfig(
    id: 'osm',
    displayName: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: 'Bản đồ © OpenStreetMap contributors',
    userAgentPackageName: 'com.example.busgo',
  );
}