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
* Из общего числа клиентов 1 672, или 15%, зарегистрировали более 1 питомца.  

__Бизнес-возможность:__ продавать оптовый продукт клиентам с несколькими домашними животными, предлагая экономически эффективный подход к кормлению их питомцев.


```sql
--Вычисление процентного соотношения разных размеров пород
WITH breed_size AS(
SELECT pet_breed_size, count(fixedcustomerid) as TotalOrders
FROM PetPetProject.dbo.petfood
WHERE year(OrderDateConverted) <> '2018'
GROUP BY pet_breed_size
)

SELECT bs.pet_breed_size, bs.TotalOrders, bs.TotalOrders * 1.0 / SUM(bs.TotalOrders) OVER () *100 AS Percentage
FROM breed_size bs
ORDER BY 3 DESC
````
+ Распределение размеров пород домашних животных разнообразно: 32 % заказов приходится на мелкие породы, 30 % - на средние и 22 % - на крупные породы

__Возможность для бизнеса__: сосредоточиться на целевых маркетинговых усилиях, удовлетворяя конкретные потребности владельцев домашних животных в зависимости от их породных предпочтений


```sql
/* Анализ данных о заказах за месяц. Сначала запрос вычисляет общее количество заказов за каждый месяц. 
Затем вычисляется изменение количества заказов по сравнению с предыдущим месяцем и процентное изменение для каждого месяца. 
Результаты сортируются по годам и месяцам, что позволяет получить хронологическое представление о динамике заказов во времени. */
WITH MonthlyOrders AS (
    SELECT 
        YEAR(OrderDateConverted) AS Year,
        MONTH(OrderDateConverted) AS Month,
        COUNT(FixedCustomerID) AS Total_Orders
    FROM PetPetProject.dbo.petfood 
    WHERE YEAR(OrderDateConverted) <> 2018
    GROUP BY YEAR(OrderDateConverted), MONTH(OrderDateConverted)
)
SELECT 
    mo.Year,
    mo.Month,
    mo.Total_Orders,
    CASE 
        WHEN LAG(mo.Total_Orders) OVER (ORDER BY mo.Year, mo.Month) 
             IS NULL THEN NULL
        ELSE mo.Total_Orders - ISNULL(LAG(mo.Total_Orders) 
                                      OVER (ORDER BY mo.Year, mo.Month), 0)
    END AS OrderChange,
    CASE 
        WHEN LAG(mo.Total_Orders) OVER (ORDER BY mo.Year, mo.Month) 
             IS NULL THEN NULL
        WHEN ISNULL(LAG(mo.Total_Orders) 
             OVER (ORDER BY mo.Year, mo.Month), 0) = 0 THEN 100.0
        ELSE (1.0 * (mo.Total_Orders - ISNULL(LAG(mo.Total_Orders) 
             OVER (ORDER BY mo.Year, mo.Month), 0)) / 
              ISNULL(LAG(mo.Total_Orders) 
                  OVER (ORDER BY mo.Year, mo.Month), 0)) * 100.0
    END AS PercentageChange
FROM MonthlyOrders mo
ORDER BY mo.Year, mo.Month;

WITH CustomerStatus AS (
    SELECT
        YEAR(OrderDateConverted) AS year,
        MONTH(OrderDateConverted) AS month,
        FixedCustomerID,
        MIN(OrderDateConverted) AS first_purchase_date
    FROM PetPetProject.dbo.petfood
    WHERE YEAR(OrderDateConverted) <> '2018'
    GROUP BY YEAR(OrderDateConverted), 
    MONTH(OrderDateConverted), 
    FixedCustomerID
),

MonthlyCustomerStatus AS (
    SELECT
        cs.year,
        cs.month,
        COUNT(DISTINCT CASE WHEN mo.month IS NOT NULL 
              THEN cs.FixedCustomerID ELSE NULL END) AS existing_customers,
        COUNT(DISTINCT CASE WHEN mo.month IS NULL 
              THEN cs.FixedCustomerID ELSE NULL END) AS new_customers
    FROM CustomerStatus cs
    LEFT JOIN CustomerStatus mo
        ON cs.FixedCustomerID = mo.FixedCustomerID
        AND cs.first_purchase_date > mo.first_purchase_date
    GROUP BY cs.year, cs.month
)

SELECT
    mcs.year,
    mcs.month,
    mcs.existing_customers,
    mcs.new_customers,
    (mcs.existing_customers * 100.0) / 
        (mcs.existing_customers + mcs.new_customers)
        AS ExistingCustomersPercentage,
    (mcs.new_customers * 100.0) / (mcs.existing_customers + mcs.new_customers)
        AS NewCustomersPercentage
FROM MonthlyCustomerStatus mcs
ORDER BY mcs.year, mcs.month;
```
- Количество новых клиентов постоянно увеличивалось из месяца в месяц, начиная с января 2019 года, а самый высокий процент новых клиентов (41%) наблюдался в октябре 2019 года
- Однако в марте 2022 года процент новых клиентов достиг своего минимума. Это может быть связано с резким увеличением числа новых клиентов в последние месяцы. До марта 2022 года среднемесячное количество новых клиентов с декабря 2019 года по февраль 2020 года составляло 1439 человек, что на 151 % больше по сравнению со среднемесячным количеством с января 2019 года по ноябрь 2019 года
- Удержание клиентов демонстрирует устойчивый рост из месяца в месяц. Например, в августе 2019 года было 1165 заказов от существующих клиентов, которые более чем удвоились и достигли 3907 в декабре 2019 года  
__Бизнес-возможность:__ Внедрение и активное продвижение новых продуктов для привлечения неосвоенных сегментов клиентов  


```sql

WITH AllergenStatus AS (
    SELECT
        Fixedcustomerid,
        CASE WHEN MAX(CASE WHEN pet_allergen_list IS NOT NULL 
            THEN 1 ELSE 0 END) = 1 THEN 'Yes' ELSE 'No' END AS Pet_has_Allergen
    FROM PetPetProject.dbo.petfood
    WHERE Year(OrderDateConverted) <> '2018'
    GROUP BY Fixedcustomerid
),  
OrdersPerCustomer AS (
    SELECT
        Fixedcustomerid,
        COUNT(*) AS Total_Orders
    FROM PetPetProject.dbo.petfood
    GROUP BY Fixedcustomerid
),  
TotalCustomersAndOrders AS ( 
    SELECT
        a.Pet_has_Allergen,
        COUNT(DISTINCT o.FixedCustomerID) AS Total_Customers,
        SUM(o.Total_Orders) AS Total_Orders
    FROM OrdersPerCustomer o
    JOIN AllergenStatus a ON o.FixedcustomerID = a.FixedcustomerID
    GROUP BY a.Pet_has_allergen
)  

SELECT
    tca.Pet_has_Allergen,
    tca.Total_Customers,
    tca.Total_Orders,
    tca.Total_Customers * 1.0 / SUM(tca.Total_Customers) OVER() 
        AS Percent_Customers,
    tca.Total_Orders * 1.0 / SUM(tca.Total_Orders) OVER() AS Percent_Orders

FROM TotalCustomersAndOrders tca;
```
* Из общего числа зарегистрированных домашних животных 2 610 имеют аллегрию, что составляет 20 % от общего числа домашних животных  

```sql
/* Посмотрим, есть ли взаимосвязи между аллергией у питомцев и покупательскими привычками клиентов*/  
WITH AllergenStatus AS (
    SELECT
        Fixedcustomerid,
        MAX(CASE WHEN pet_allergen_list IS NOT NULL THEN 1 ELSE 0 END) 
        AS Pet_has_Allergen
    FROM PetPetProject.dbo.petfood
    WHERE Year(OrderDateConverted) <> '2018'
    GROUP BY Fixedcustomerid
),

TotalCustomersAndOrders AS (
    SELECT
        a.Pet_has_Allergen,
        COUNT(DISTINCT o.FixedCustomerID) AS Total_Customers,
        SUM(COUNT(*)) OVER () AS Total_Orders,
        COUNT(*) AS Total_OrdersPerAllergen
    FROM PetPetProject.dbo.petfood o
    JOIN AllergenStatus a ON o.FixedcustomerID = a.FixedcustomerID
    GROUP BY a.Pet_has_Allergen
)

SELECT
    CASE WHEN tca.Pet_has_Allergen = 0 THEN 'No' ELSE 'Yes' END 
        AS Pet_has_Allergen,
    tca.Total_Customers,
    tca.Total_Orders,
    tca.Total_Customers * 1.0 / SUM(tca.Total_Customers) 
        OVER () AS Percent_Customers,
    tca.Total_Orders * 1.0 / SUM(tca.Total_OrdersPerAllergen) 
        OVER () AS Percent_Orders
FROM TotalCustomersAndOrders tca;

```
*Видим, что существует некая связь: В среднем клиенты с домашними животными, страдающими аллергией, размещают 5.0 заказов, что на 19% больше, чем клиенты, чьи домашние животные без аллергий  

```sql
/*HealthIssueStatus показывает клиентов, у чьих питомцев с проблемами со здоровьем, проверяя на пустоту список заболеваний их животных*/  
WITH HealthIssueStatus AS (
    SELECT
        Fixedcustomerid,
    MAX(CASE WHEN pet_health_issue_list IS NOT NULL THEN 1 ELSE 0 END) 
        AS Pet_has_Health_Issue
    FROM PPetPetProject.dbo.petfood
    GROUP BY Fixedcustomerid
),

/*Считаем общее количество заказов для каждого клиента, группируя по ID*/  

OrdersPerCustomer AS (
    SELECT
        Fixedcustomerid,
        COUNT(*) AS Total_Orders
    FROM PetPetProject.dbo.petfood
    GROUP BY Fixedcustomerid
),

TotalCustomersAndOrders AS ( 
    SELECT
        a.Pet_has_Health_Issue,
        COUNT(DISTINCT o.FixedCustomerID) AS Total_Customers,
        SUM(o.Total_Orders) AS Total_Orders
    FROM OrdersPerCustomer o
    JOIN HealthIssueStatus a ON o.FixedcustomerID = a.FixedcustomerID
    GROUP BY a.Pet_has_Health_Issue
)

/*Преобразуем значение Pet_has_Health_Issue в Да и Нет для наглядности, отразим количество клиентов и заказов для каждой группы (в абсолютном и процентном соотношении)*/
SELECT  
    CASE WHEN tca.Pet_has_Health_Issue = 0 THEN 'No' ELSE 'Yes' END 
        AS Pet_has_health_issue,
    tca.Total_Customers,
    tca.Total_Orders,
    tca.Total_Customers * 1.0/ SUM(tca.Total_Customers) OVER () 
        AS Percent_Customers,
    tca.Total_Orders * 1.0/ SUM(tca.Total_Orders) OVER () AS Percent_Orders
FROM TotalCustomersAndOrders tca;
```
*Видим взаимосвязь: клиенты с домашними животными, страдающими заболеваниями, размещают 4.69 заказов, что на 14.5% больше, чем клиенты, чьи питомцы полностью здоровы  
*5609 покупателей, или 50% от общего числа покупателей, указали, что у их питомца есть проблемы со здоровьем  

__Бизнес-возможность:__  Приоретезировать продвижение кормов для питомцев с заболеваниями, а не для питомцев с аллергией из-за более высокой распространенности проблем со здоровьем (50%) по сравнению с аллергией (20%)
