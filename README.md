# pet_pet_project

В этом проекте я использую SQL для изучения основных показателей и трендов в данных  
Разведочный анализ данных производится на основе биг [датасета](https://www.kaggle.com/datasets/jahangirraina/pet-food-customer-orders-online) продаж магазина c Kaggle: анализируя данные о продажах в зоомагазине, выявить идеи и тенденции в работы бизнеса и определить, как они могут улучшить маркетинговую стратегию компании

Так как данные зачастую бывают неидеальными, то требуется предобработка. Что и как было проделано вынесено в отдельный файл `data_manipulation`

Непосредственно анализ:

```sql
-- Считаем общее количество покупателей, питомцев и заказов в датасете для заказов не 2018 
    
SELECT 
    COUNT(DISTINCT FixedCustomerID) AS TotalCustomer, 
    Count(Distinct FixedPetID) AS TotalPet, 
    COUNT(FixedCustomerID) AS TotalOrder
FROM PetPetProject.dbo.petfood
WHERE  Year(OrderDateConverted) <> '2018'

-- Вычисление среднего количества домашних животных на одного клиента
SELECT 
    CAST(COUNT(DISTINCT FixedPetID) * 1.0 
    / COUNT(DISTINCT FixedCustomerID) AS DECIMAL(10, 2)) AS Pets_per_Customer
FROM PetPetProject.dbo.petfood
WHERE  Year(OrderDateConverted) <> '2018'

-- Подсчет общего количества клиентов, имеющих более одного питомца (общего количества уникальных клиентов и в процентах от общего количества клиентов)
SELECT 
    COUNT(DISTINCT CASE WHEN PetCount > 1 THEN FixedCustomerID END) 
    AS TotalCustomerWithMultiplePets,
    COUNT(DISTINCT FixedCustomerID) AS TotalCustomers,
    (COUNT(DISTINCT CASE WHEN PetCount > 1 THEN FixedCustomerID END) * 100.0) 
    / COUNT(DISTINCT FixedCustomerID) AS PercentageCustomersWithMultiplePets
FROM (
    SELECT FixedCustomerID, COUNT(DISTINCT FixedPetID) AS PetCount
    FROM PetPetProject.dbo.petfood 
    WHERE Year(OrderDateConverted) <> '2018'
    GROUP BY FixedCustomerID
) AS subquery;

```
-Сколько клиентов зарегистрировали более 1 питомца?
Из общего числа клиентов 1 672, или 15%, зарегистрировали более 1 питомца.  

__Бизнес-возможность:__ продавать оптовый продукт клиентам с несколькими домашними животными, предлагая экономически эффективный подход к кормлению их питомцев.
