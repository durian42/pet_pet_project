# pet_pet_project

В этом проекте я использую SQL для изучения основных показателей и трендов в данных  
Разведочный анализ данных производится на основе биг [датасета](https://www.kaggle.com/datasets/jahangirraina/pet-food-customer-orders-online) продаж магазина c Kaggle: анализируя данные о продажах в зоомагазине, выявить идеи и тенденции в работы бизнеса и определить, как они могут улучшить маркетинговую стратегию компании

```sql
-- Считаем общее количество покупателей, питомцев и заказов в датасете для заказов не 2018 года 
    
SELECT 
    COUNT(DISTINCT FixedCustomerID) AS TotalCustomer, 
    Count(Distinct FixedPetID) AS TotalPet, 
    COUNT(FixedCustomerID) AS TotalOrder
FROM PortfolioProject.dbo.petfood
WHERE  Year(OrderDateConverted) <> '2018'
```
