
											-- CLEANING DATA IN SQL QUERIES --
	SELECT *
		FROM nashville_housing_data;
    -- ------------------------------------------------------------------------------------------------------------ --
    SET SQL_SAFE_UPDATES = 0; -- to toggle safemode off if want to use update without where clause
	-- ------------------------------------------------------------------------------------------------------------ --
											-- STANDARDIZE DATE FORMAT --
                                            
	SELECT str_to_date(SaleDate, '%M %d, %Y') as converted_date
		FROM nashville_housing_data;
        
	ALTER TABLE nashville_housing_data
	ADD COLUMN Sale_Date DATE;
    
	BEGIN;
	--  SAVEPOINT converted_date;
		UPDATE nashville_housing_data
        SET Sale_Date = str_to_date(SaleDate, '%M %d, %Y')
		WHERE SaleDate = SaleDate;
	--  RELEASE SAVEPOINT converted_date;
	SAVEPOINT converted_date_new;
	COMMIT;
    
    ALTER TABLE nashville_housing_data
	DROP COLUMN SaleDate;
    -- ------------------------------------------------------------------------------------------------------------ --
											-- Populating Property Address data that has null values --
	SELECT *
		FROM nashville_housing_data
        WHERE PropertyAddress is null
        ORDER BY ParcelID;
        
	SELECT a.ParcelID , a.PropertyAddress, b.ParcelID, b.PropertyAddress , IFNULL(a.PropertyAddress, b.PropertyAddress) as s
		FROM nashville_housing_data AS a
		JOIN nashville_housing_data AS b
			on a.ParcelID = b.ParcelID
			and a.UniqueID != b.UniqueID
		WHERE a.PropertyAddress IS NULL;
    
    BEGIN;
		UPDATE nashville_housing_data AS a
		JOIN nashville_housing_data AS b
			on a.ParcelID = b.ParcelID
			and a.UniqueID != b.UniqueID
		SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
		WHERE a.PropertyAddress IS NULL;
	COMMIT;
    -- ------------------------------------------------------------------------------------------------------------ --
										-- Breaking out Address into individual columns (Address, City , State) -- 
	SELECT PropertyAddress
		FROM nashville_housing_data;
            
	SELECT  substring(PropertyAddress, 1, instr(PropertyAddress, ',') -1 ) as Address,
			substring(PropertyAddress, instr(PropertyAddress, ',') + 1, length(PropertyAddress)) as City
		FROM nashville_housing_data;
	
    ALTER TABLE nashville_housing_data
			ADD Address VARCHAR(255),
            ADD City VARCHAR(255);
            
    BEGIN;
	--  SAVEPOINT ADDRESS_CITY;
		UPDATE nashville_housing_data
			SET Address = substring(PropertyAddress, 1, instr(PropertyAddress, ',') -1 ),
				City    = substring(PropertyAddress, instr(PropertyAddress, ',') + 1, length(PropertyAddress));
	COMMIT;
	
    SELECT OwnerAddress
		FROM nashville_housing_data;
	
	SELECT  SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'),'.', 1) AS A,
			SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'),'.', -2),'.', 1) AS B,
            SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'),'.', -1) AS C
		FROM nashville_housing_data;
        
	ALTER TABLE nashville_housing_data
			ADD COLUMN OwnersplitAddress VARCHAR(255),
			ADD	COLUMN OwnersplitCity    VARCHAR(255),
			ADD COLUMN OwnerplitState    VARCHAR(255);
	
	BEGIN;
        UPDATE nashville_housing_data
			SET OwnersplitAddress = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'),'.', 1),
				OwnersplitCity    = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'),'.', -2),'.', 1),
                OwnerplitState    = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'),'.', -1);
		SELECT * FROM nashville_housing_data
        
	COMMIT;
    -- ------------------------------------------------------------------------------------------------------------ --
										-- CHANGE 'Y' AND 'N' TO YES AND NO IN SOLD AS VACANT FIELD
	SELECT distinct(SoldAsVacant), count(*),
		CASE 
			WHEN SoldAsVacant = 'Y' THEN 'YES'
            WHEN SoldAsVacant = 'N' THEN 'NO'
            else SoldAsVacant
		END
		FROM nashville_housing_data
        GROUP BY SoldAsVacant;
	
    BEGIN;
		UPDATE nashville_housing_data
			SET SoldAsVacant = CASE 
									WHEN SoldAsVacant = 'Y' THEN 'YES'
									WHEN SoldAsVacant = 'N' THEN 'NO'
									else SoldAsVacant
								END;
	COMMIT;
			
    
    -- ------------------------------------------------------------------------------------------------------------ --
									-- REMOVING DUPPLICATES --
	WITH CTE_ROW_NUM AS (
		SELECT UniqueID
		FROM (
			SELECT UniqueID,
				   ROW_NUMBER() OVER(PARTITION BY ParcelID, Sale_Date, PropertyAddress, SalePrice, LegalReference
					   ORDER BY UniqueID) AS NUM_OF_DUPP
			FROM nashville_housing_data
		) AS subquery
		WHERE NUM_OF_DUPP > 1 
	)
    
    -- SELECT NHD.UniqueID
    DELETE NHD
		FROM nashville_housing_data AS NHD
        JOIN CTE_ROW_NUM AS CTE
        ON NHD.UniqueID = CTE.UniqueID;
        
	-- Sulotion 2
    DELETE FROM nashville_housing_data
		WHERE UniqueID NOT IN (SELECT MIN(UniqueID)
									FROM nashville_housing_data
										GROUP BY UniqueID, ParcelID);
    -- ------------------------------------------------------------------------------------------------------------ --
									-- DELETING UNUSED COLUMNS --
	SELECT * 
		FROM nashville_housing_data;
        
	ALTER TABLE nashville_housing_data
		DROP COLUMN OwnerAddress,
		DROP COLUMN TaxDistrict,
		DROP COLUMN PropertyAddress;
	SELECT *
		FROM nashville_housing_data
						
    -- ------------------------------------------------------------------------------------------------------------ --
    -- ------------------------------------------------------------------------------------------------------------ --
    -- ------------------------------------------------------------------------------------------------------------ --