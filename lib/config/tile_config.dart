// tile_config.dart
// Cấu hình TẬP TRUNG cho nguồn bản đồ (tile provider).
//
// Mục đích:
//  - Không hardcode URL/attribution trực tiếp trong Widget.
//  - Tách riêng URL tile, tên gói User-Agent và attribution.
//  - Mặc định dùng Esri World Street Map (raster, có đầy đủ tên đường/nhãn),
//    OpenStreetMap được cấu hình sẵn làm phương án dự phòng.
//
// LƯU Ý: tile công cộng chỉ phù hợp cho demo/đồ án, KHÔNG phải giải pháp
// production lâu dài. Khi triển khai thật nên dùng nhà cung cấp tile riêng
// (có API key) hoặc tile server tự vận hành.
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

  // Nguồn tile ĐANG dùng. Muốn chuyển sang OpenStreetMap đổi dòng này thành:
  //   static final TileProviderConfig current = TileConfig.osm;
  static final TileProviderConfig current = TileConfig.esri;

  // Esri World Street Map - MẶC ĐỊNH.
  // Raster tile (KHÔNG phải VectorTileServer) nên dùng trực tiếp với
  // TileLayer. LƯU Ý thứ tự tham số của Esri là {z}/{y}/{x}, KHÔNG phải
  // {z}/{x}/{y} như phần lớn nhà cung cấp khác.
  static const TileProviderConfig esri = TileProviderConfig(
    id: 'esri',
    displayName: 'Esri World Street Map',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    // SimpleAttributionWidget tự thêm tiền tố "© " trước source, nên ở đây
    // ghi nguồn tile chính (Esri) cùng nguồn dữ liệu, tránh chỉ ghi OSM.
    attribution: 'Esri, HERE, Garmin, © OpenStreetMap contributors',
    userAgentPackageName: 'com.example.busgo',
  );

  // OpenStreetMap - phương án dự phòng (miễn phí, không cần API key).
  // LƯU Ý: widget SimpleAttributionWidget tự thêm tiền tố "© " nên ở đây
  // chỉ ghi phần tên nguồn; trên bản đồ sẽ hiển thị đúng
  // "© OpenStreetMap contributors" theo yêu cầu của OSM Foundation.
  static const TileProviderConfig osm = TileProviderConfig(
    id: 'osm',
    displayName: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: 'OpenStreetMap contributors',
    userAgentPackageName: 'com.example.busgo',
  );
}
