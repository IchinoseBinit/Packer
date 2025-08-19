import 'package:flutter/material.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/damage_products/controller/damage_product_controller.dart';
import 'package:packer/features/views/widgets/file_upload.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class RackProductList extends StatefulWidget {
  const RackProductList({super.key});

  @override
  State<RackProductList> createState() => _RackProductListState();
}

class _RackProductListState extends State<RackProductList> {
  @override
  Widget build(BuildContext context) {
    final damageProductController =
        Provider.of<DamageProductController>(context, listen: false);

    final productList = damageProductController.rackProductList;
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: Text("Rack Product List"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              ListView.separated(
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      fileUpload(context, productList[index].id,
                          productList[index].quantity);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(productList[index].name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ID: ${productList[index].id}"),
                            Text("Quantity: ${productList[index].quantity}"),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                itemCount: productList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
