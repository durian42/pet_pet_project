Format for Customer_ID and Pet_ID 
ALTER Table petfood
ADD FixedPetID Numeric (24,0),
    FixedCustomerID Numeric (24,01);

UPDATE petfood
SET
    FixedCustomerID = CONVERT(NUMERIC(24, 0), customer_id),
    FixedPetID = CONVERT(NUMERIC(24, 0), pet_id);

ALTER TABLE petfood
ADD Pet_has_Allergen VARCHAR (3),
    Pet_has_health_issue VARCHAR (3);
    
UPDATE petfood
SET 
    Pet_has_Allergen = CASE WHEN pet_allergen_list IS NOT NULL THEN 'Yes'
    ELSE 'No'
    END,
    Pet_has_health_issue = CASE WHEN Pet_has_health_issue IS NOT NULL THEN 'Yes'
    ELSE 'No'
    END;

ALTER TABLE petfood
ADD OrderDateConverted DATE;

UPDATE petfood
SET OrderDateConverted = CONVERT(DATE,Order_Payment_Date)
