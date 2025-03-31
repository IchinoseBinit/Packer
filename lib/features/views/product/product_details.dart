import 'package:flutter/material.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:provider/provider.dart';

class ProductDetail extends StatelessWidget {
  const ProductDetail({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    List<String> scannedDataList = provider.scannedDataList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Products List'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: scannedDataList.isEmpty
            ? const Center(child: Text("No products found"))
            : ListView.builder(
                itemCount: scannedDataList.length,
                itemBuilder: (context, index) {
                  try {
                    // final data = jsonDecode(scannedDataList[index])
                    //     as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(scannedDataList[index]),
                      ),
                    );
                  } catch (e) {
                    return const ListTile(
                      title: Text("Invalid QR Code Data"),
                    );
                  }
                },
              ),
      ),
    );
  }
}
