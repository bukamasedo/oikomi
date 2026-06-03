import Charts
import OikomiKit
import SwiftUI

/// 軸を持たないミニ・スパークライン。推定1RM 推移などの短い時系列を
/// AreaMark + LineMark（catmullRom）+ 末尾 PointMark で描く。
/// ホームの自己ベストカードとコーチングカードで共有する（枠・サイズは呼び出し側が `.frame` で与える）。
struct MiniSparkline: View {

    /// 表示単位へ変換済みの時系列（古い順）。2 点未満では呼び出し側が出さない前提。
    let series: [Double]
    var tint: Color = OikomiColor.brandSecondary

    var body: some View {
        let lo = series.min() ?? 0
        let hi = series.max() ?? 1
        // 平坦な系列でも線が潰れないよう上下に余白を与える。
        let pad = max((hi - lo) * 0.18, 0.5)
        let points = Array(series.enumerated())
        Chart {
            ForEach(points, id: \.offset) { index, value in
                AreaMark(
                    x: .value("回", index),
                    yStart: .value("ベース", lo - pad),
                    yEnd: .value("推定1RM", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [tint.opacity(0.22), tint.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom))

                LineMark(
                    x: .value("回", index),
                    y: .value("推定1RM", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            if let lastValue = series.last {
                PointMark(
                    x: .value("回", points.count - 1),
                    y: .value("推定1RM", lastValue)
                )
                .foregroundStyle(tint)
                .symbolSize(26)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (lo - pad)...(hi + pad))
        .accessibilityLabel("推定1RM の推移グラフ")
    }
}

#Preview {
    MiniSparkline(series: [78, 80, 82, 81, 88, 90, 95])
        .frame(width: 72, height: 34)
        .padding()
        .background(OikomiColor.appBackground)
}
