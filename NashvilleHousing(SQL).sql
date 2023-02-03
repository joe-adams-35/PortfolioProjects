/*

Cleaning data in SQL Queries

*/

SELECT *
FROM HousingData.dbo.house

----------------------------------------------------------------------------------

-- Standardize Date Format

SELECT SaleDate, CAST(SaleDate as date) AS SaleDateConverted
FROM HousingData.dbo.house

----------------------------------------------------------------------------------

-- Populate Property Address Data

SELECT *
FROM HousingData.dbo.house
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingData.dbo.house a
JOIN HousingData.dbo.house b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingData.dbo.house a
JOIN HousingData.dbo.house b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is NULL

----------------------------------------------------------------------------------

--Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM HousingData.dbo.house

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM HousingData.dbo.house

ALTER TABLE HousingData.dbo.house
ADD PropertySplitAddress Nvarchar(255);

UPDATE HousingData.dbo.house
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE HousingData.dbo.house
ADD PropertySplitCity Nvarchar(255)

UPDATE HousingData.dbo.house
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


SELECT OwnerAddress
From HousingData.dbo.house

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From HousingData.dbo.house

ALTER TABLE HousingData.dbo.house
ADD OwnerSplitAddress Nvarchar(255);

UPDATE HousingData.dbo.house
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE HousingData.dbo.house
ADD OwnerSplitCity Nvarchar(255)

UPDATE HousingData.dbo.house
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE HousingData.dbo.house
ADD OwnerSplitState Nvarchar(255)

UPDATE HousingData.dbo.house
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

----------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingData.dbo.house
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END
FROM HousingData.dbo.house

UPDATE HousingData.dbo.house
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END

----------------------------------------------------------------------------------

-- Remove Duplicates
-- CTE

WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
                ORDER BY
                UniqueID
) row_num
FROM HousingData.dbo.house
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

----------------------------------------------------------------------------------

-- Delete Unused Columns
SELECT *
FROM HousingData.dbo.house

ALTER TABLE HousingData.dbo.house
DROP COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress

