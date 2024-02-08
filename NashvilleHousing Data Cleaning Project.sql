--Nashville Housing Data Cleaning
Select *
From [Nashville Housing].dbo.NashvilleHousing

-------------------------------------------------------------------------------------

-- Standardize Date Format

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

--checking the update
Select SaleDateConverted, CONVERT(Date,SaleDate)
From [Nashville Housing].dbo.NashvilleHousing



---------------------------------------------------------------------------------------

-- Populate Property Address data


--checking data
Select * 
From [Nashville Housing].dbo.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID


--querying the solution using ISNULL function
--ISNULL will replace the null values with specified values that we choose
Select	a.ParcelID, 
		a.PropertyAddress, 
		b.ParcelID, 
		b.PropertyAddress, 
		ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Nashville Housing].dbo.NashvilleHousing a
JOIN [Nashville Housing].dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


--applying solution using update
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Nashville Housing].dbo.NashvilleHousing a
JOIN [Nashville Housing].dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


--check if there's a null values
Select *
From [Nashville Housing].dbo.NashvilleHousing
Where PropertyAddress is null
order by ParcelID


----------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


--checking PropertyAddress data
Select PropertyAddress
From [Nashville Housing].dbo.NashvilleHousing

--Querying solution (1st METHOD)
--Using SUBSTRING & CHARINDEX to substract/breaking out the proverty address
--CHARINDEX would return the position of comma ',' in the string
--SUBSTRING would return the part of string that we want to show, and has 3 arguments, SUBSTRING( expression, start, length )  
SELECT
		PropertyAddress,
		 SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Street -- -1 used to remove the comma
		,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as City -- +1 used to remove comma
From [Nashville Housing].dbo.NashvilleHousing

--Applying Solution using ALTER TABLE & UPDATE
ALTER TABLE NashvilleHousing
Add PropertyStreet Nvarchar(255);

Update NashvilleHousing
SET PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing
Add PropertyCity Nvarchar(255);

Update NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

--checking the data
select
		PropertyAddress,
		propertyStreet,
		propertyCity
from [Nashville Housing].dbo.NashvilleHousing



--Querying solution (2nd Method)
--Using PARSENAME to breaking out the string
--PARSENAME return the substring based on delimeter (dot '.') position
--Note : the delimeter must be dot '.', thats why we have to replace the comma with dot
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From [Nashville Housing].dbo.NashvilleHousing


--Applying the query
ALTER TABLE NashvilleHousing
Add OwnerAddressStreet Nvarchar(255),
	OwnerAddressCity Nvarchar(255),
	OwnerAddressState Nvarchar(255)

Update NashvilleHousing
SET OwnerAddressStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
	OwnerAddressCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
	OwnerAddressState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

--checking value
select *
from NashvilleHousing



------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

--Checking values
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From [Nashville Housing].dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

--Querying Solution with CASE Statement
Select SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
From [Nashville Housing].dbo.NashvilleHousing

--Updating Column Values
UPDATE NashvilleHousing
SET SoldAsVacant =	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						 WHEN SoldAsVacant = 'N' THEN 'No'
						 ELSE SoldAsVacant
						 END
					From [Nashville Housing].dbo.NashvilleHousing



-------------------------------------------------------------------------------------

--Remove Duplicate


--Detecting Duplicate values using ROW_NUMBERS
--Any Row_Number > 1 is a duplicate values 
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From [Nashville Housing].dbo.NashvilleHousing
order by ParcelID

--Showing Duplicate Values using CTE and ROW_NUMBERS
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From [Nashville Housing].dbo.NashvilleHousing
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

--Deleting Duplicate Values using  DELETE, CTE and ROW_NUMBERS
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From [Nashville Housing].dbo.NashvilleHousing
)
delete
From RowNumCTE
Where row_num > 1

Select *
From [Nashville Housing].dbo.NashvilleHousing

---------------------------------------------------------------------------------------


--Deleting Unused Columns
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


Select *
From [Nashville Housing].dbo.NashvilleHousing
