---
layout: home
title: Data Sources
---

*All data is publically available from the City Government.*

| Source name | Name in code | Link to data | Link to metadata | Explanation |
| ----------- | ----------- | ----------- | ----------- |----------- |
| MapPLUTO (Shoreline Clipped) | `mappluto` | [Link](https://www.nyc.gov/content/planning/pages/resources/datasets/mappluto-pluto-change) | [Link](https://s-media.nyc.gov/agencies/dcp/assets/files/pdf/data-tools/bytes/meta_mappluto.pdf) | Department of City Planning tax lot data to use as the "parcels" in analysis.
| MTA Subway Entrances and Exits: 2024 | `subway_ee` | [Link](https://data.ny.gov/Transportation/MTA-Subway-Entrances-and-Exits-2024/i9wp-a4ja/about_data) | [Link](https://data.ny.gov/api/views/i9wp-a4ja/files/aa69cf4f-41d5-47f0-b421-aade8737ae93?download=true&filename=MTA_SubwayEntrancesAndExits_DataDictionary.pdf) | MTA entrance and exit points for New York City Subway and Staten Island Railway stations.
| LION | `lion` | [Link](https://data.cityofnewyork.us/City-Government/LION/2v4z-66xt/about_data) | [Link](https://data.cityofnewyork.us/api/views/2v4z-66xt/files/8f0f61c0-aa6a-4f99-a9bc-a97b2c43b584?download=true&filename=lion_metadata.pdf) | Department of City Planning single line street base map to use as network.
| 2020 Neighborhood Tabulation Areas (NTAs) | `ntas` | [Link](https://data.cityofnewyork.us/City-Government/2020-Neighborhood-Tabulation-Areas-NTAs-/9nt8-h7nd/about_data) | [Link](https://data.cityofnewyork.us/api/views/9nt8-h7nd/files/4973fec4-68b5-49ab-9532-f3ccbd5225cb?download=true&filename=nynta2020_metadata.pdf)| Department of City Planning NTAs (rough correspondance to commonly recognized neighborhoods), for neighborhood-level subway access analysis. |
| Borough Boundaries | `boroughs` | [Link](https://data.cityofnewyork.us/City-Government/Borough-Boundaries/gthc-hcne/about_data) | [Link](https://data.cityofnewyork.us/api/views/gthc-hcne/files/5cf29396-4a72-4951-ba6d-43019cf55641?download=true&filename=nybb_metadata.pdf) | Department of City Planning boundaries of boroughs (water areas excluded), for borough-level subway access analysis. |

***

`mappluto` and `lion` were already in the project CRS, EPSG:2263. `subway_ee`, `ntas`, and `boroughs` were all reprojected in QGIS from OGC:CRS84 to EPSG:2263 before running queries.