import { mkdir, writeFile } from 'node:fs/promises'
import { dirname } from 'node:path'

const SOURCE = {
  productId: 'LDEM_875S_5M',
  imageUrl: 'https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_5m_float.img',
  labelUrl: 'https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_5m_float.lbl',
  rows: 30336,
  cols: 30336,
  recordBytes: 121344,
  sampleBytes: 4,
  mapScaleM: 5,
  unit: 'kilometer',
}

const TILE = {
  tileId: 'first-trusted-square-lola-5m-129',
  siteLatitudeDeg: -89.88,
  siteLongitudeDeg: 0.12,
  rows: 129,
  cols: 129,
  // Aligned to the checked 20 m fixture window recorded in data/sources/lro_lola/README.md.
  centerRow: 15894,
  centerCol: 15166,
  outputPath: 'assets/lro_lola/first_trusted_square_lola_5m_129.json',
}

async function fetchRange(url, start, end) {
  const response = await fetch(url, {
    headers: { Range: `bytes=${start}-${end}` },
  })
  if (!response.ok && response.status !== 206) {
    throw new Error(`failed to fetch ${url}: HTTP ${response.status}`)
  }
  if (response.status !== 206) {
    throw new Error(`server did not honor range request for ${url}`)
  }
  return Buffer.from(await response.arrayBuffer())
}

function minMax(values) {
  let min = Infinity
  let max = -Infinity
  for (const row of values) {
    for (const value of row) {
      min = Math.min(min, value)
      max = Math.max(max, value)
    }
  }
  return { min, max }
}

async function main() {
  const startRow = TILE.centerRow - Math.floor(TILE.rows / 2)
  const startCol = TILE.centerCol - Math.floor(TILE.cols / 2)
  const endRow = startRow + TILE.rows - 1
  const startByte = startRow * SOURCE.recordBytes
  const endByte = (endRow + 1) * SOURCE.recordBytes - 1
  const sourceBlock = await fetchRange(SOURCE.imageUrl, startByte, endByte)
  const elevationsM = []
  for (let row = 0; row < TILE.rows; row += 1) {
    const values = []
    const rowOffset = row * SOURCE.recordBytes
    for (let col = 0; col < TILE.cols; col += 1) {
      const offset = rowOffset + (startCol + col) * SOURCE.sampleBytes
      values.push(Number((sourceBlock.readFloatLE(offset) * 1000).toFixed(3)))
    }
    elevationsM.push(values)
  }
  const stats = minMax(elevationsM)
  const asset = {
    tile_id: TILE.tileId,
    source: {
      product_id: SOURCE.productId,
      image_url: SOURCE.imageUrl,
      label_url: SOURCE.labelUrl,
      instrument: 'LRO LOLA',
      projection: 'polar stereographic',
      source_unit: SOURCE.unit,
      source_map_scale_m: SOURCE.mapScaleM,
    },
    site: {
      latitude_deg: TILE.siteLatitudeDeg,
      longitude_deg: TILE.siteLongitudeDeg,
      alignment: 'centered on checked first_trusted_square 20 m fixture window',
    },
    grid: {
      rows: TILE.rows,
      cols: TILE.cols,
      cell_size_m: SOURCE.mapScaleM,
      source_start_row: startRow,
      source_start_col: startCol,
      source_center_row: TILE.centerRow,
      source_center_col: TILE.centerCol,
      min_elevation_m: Number(stats.min.toFixed(3)),
      max_elevation_m: Number(stats.max.toFixed(3)),
      height_range_m: Number((stats.max - stats.min).toFixed(3)),
    },
    elevations_m: elevationsM,
  }
  await mkdir(dirname(TILE.outputPath), { recursive: true })
  await writeFile(`${TILE.outputPath}`, `${JSON.stringify(asset)}\n`)
  console.log(`wrote ${TILE.outputPath}`)
  console.log(`height range: ${asset.grid.height_range_m} m`)
}

await main()
