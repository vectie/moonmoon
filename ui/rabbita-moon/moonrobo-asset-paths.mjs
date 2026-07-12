import { existsSync, statSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

export const moonroboRoot = fileURLToPath(new URL('../../../moonrobo', import.meta.url))

const generatedAssetPackRoot = fileURLToPath(
  new URL('./.generated/e1-asm-assets/e1_asm_251028', import.meta.url),
)
const assetPackRoot = process.env.MOONROBO_E1_ASSET_ROOT || generatedAssetPackRoot
const contractPackPrefix = 'examples/noetix-e1/e1_asm_251028/'

function linkIdForMeshPath(localPath) {
  return localPath.split('/').pop()?.replace(/\.[^.]+$/, '') ?? 'unknown_link'
}

function resolveMesh(localPath) {
  const repositoryPath = path.join(moonroboRoot, localPath)
  if (existsSync(repositoryPath)) {
    return {
      absolutePath: repositoryPath,
      assetUri: `moonrobo://${localPath}`,
      resolvedFrom: 'moonrobo-repository',
    }
  }
  if (localPath.startsWith(contractPackPrefix)) {
    const suffix = localPath.slice(contractPackPrefix.length)
    return {
      absolutePath: path.join(assetPackRoot, suffix),
      assetUri: `moonsuite-input://noetix-e1/e1_asm_251028/${suffix}`,
      resolvedFrom: 'moonsuite-input-cache',
    }
  }
  return {
    absolutePath: repositoryPath,
    assetUri: `moonrobo://${localPath}`,
    resolvedFrom: 'unresolved',
  }
}

export function visualMeshAssets(contract) {
  const assets = contract.mesh_paths.map(localPath => {
    const resolved = resolveMesh(localPath)
    const format = localPath.split('.').pop()?.toLowerCase() ?? ''
    const exists = existsSync(resolved.absolutePath)
    return {
      link_id: linkIdForMeshPath(localPath),
      local_path: localPath,
      moonrobo_path: resolved.assetUri,
      format,
      byte_length: exists ? statSync(resolved.absolutePath).size : 0,
      source: `${resolved.resolvedFrom}:${localPath}`,
      resolved_from: resolved.resolvedFrom,
      status: exists ? `moonrobo-${format}-mesh-referenced` : 'moonrobo-mesh-missing',
    }
  })
  if (!assets.some(asset => asset.link_id === 'base_link' && asset.format === 'stl')) {
    throw new Error('MoonRobo Noetix contract did not expose base_link STL mesh')
  }
  return assets
}
